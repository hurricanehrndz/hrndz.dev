#!/usr/bin/env bash
# Copy vault pages marked `publish: true` into content/ as Hugo page bundles.
# content/notes and content/posts are generated: edit in the vault, re-run.

vault="${VAULT:-${HOME}/vaults/personal}"
repo_root="$(git rev-parse --show-toplevel)"

if [[ ! -d "${vault}" ]]; then
    printf "\e[0;31mVault not found: %s\e[0m\n" "${vault}" >&2
    exit 1
fi

# True when the leading frontmatter block contains `publish: true`.
is_published() {
    awk 'NR == 1 && !/^---$/ { exit }
         NR > 1 && /^---$/ { exit }
         /^publish:[[:space:]]*true[[:space:]]*$/ { found = 1; exit }
         END { exit !found }' "$1"
}

count=0
for section in notes posts; do
    dst="${repo_root}/content/${section}"
    find "${dst}" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

    for src in "${vault}/${section}"/*.md; do
        [[ -e "${src}" ]] || continue
        is_published "${src}" || continue

        bundle="${dst}/$(basename "${src}" .md)"
        mkdir -p "${bundle}"
        page="${bundle}/index.md"

        # Vault-relative links -> site paths:
        #   ../attachments/x.png   -> x.png            (now in the bundle)
        #   ../notes/foo.md#frag   -> /notes/foo/#frag
        #   foo.md / ./foo.md      -> /<section>/foo/  (same-folder link)
        sed -E \
            -e 's#\]\(\.\./attachments/#](#g' \
            -e 's#\]\(\.\./(notes|posts)/([^)\#]+)\.md(\#[^)]*)?\)#](/\1/\2/\3)#g' \
            -e "s#\\]\\((\\./)?([^):/\\#]+)\\.md(\\#[^)]*)?\\)#](/${section}/\\2/\\3)#g" \
            "${src}" >"${page}"

        # Images live in the vault's attachments/; bundle the ones this page
        # uses. Photos and screenshots become WebP at most 2000px wide (the
        # theme serves up to 1320w) with metadata such as GPS stripped.
        # Obsidian percent-encodes spaces in markdown links.
        { grep -oE '\]\(\.\./attachments/[^) ]+' "${src}" || true; } |
            sed -E 's#^\]\(\.\./attachments/##' | sort -u |
            while read -r asset; do
                file="$(printf '%b' "${asset//%/\\x}")"
                case "${file,,}" in
                *.jpg | *.jpeg) opts="Q=82,keep=none" ;;
                *.png) opts="lossless,keep=none" ;;
                *)
                    cp "${vault}/attachments/${file}" "${bundle}/"
                    continue
                    ;;
                esac
                vipsthumbnail "${vault}/attachments/${file}" --size '2000x>' \
                    -o "${bundle}/${file%.*}.webp[${opts}]"
                text="$(<"${page}")"
                printf '%s\n' "${text//"](${asset}"/"](${asset%.*}.webp"}" >"${page}"
            done

        count=$((count + 1))
    done
done

# A link to a page that isn't published would 404 on the site.
broken=0
while IFS=: read -r file target; do
    if [[ ! -d "${repo_root}/content/${target}" ]]; then
        printf "\e[0;33mUnpublished link target %s in %s\e[0m\n" "${target}" "${file#"${repo_root}"/}" >&2
        broken=1
    fi
done < <(grep -roE '\]\(/(notes|posts)/[^/)#]+/' "${repo_root}/content/notes" "${repo_root}/content/posts" |
    sed -E 's#^(.*):\]\(/(.*)/$#\1:\2#')

# Links into other vault folders (wiki/, projects/, ...) aren't rewritten above
# and would 404 as well. URLs are skipped: they contain a colon.
while IFS=: read -r file link; do
    printf "\e[0;33mUnconverted vault link %s in %s\e[0m\n" "${link}" "${file#"${repo_root}"/}" >&2
    broken=1
done < <(grep -roE '\]\([^):]+\.md(#[^)]*)?\)' "${repo_root}/content/notes" "${repo_root}/content/posts")

printf "\e[1;92mPublished %d pages from %s\e[0m\n" "${count}" "${vault}"
[[ ${broken} == 0 ]] || exit 1
