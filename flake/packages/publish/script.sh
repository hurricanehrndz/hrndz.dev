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

# Pages are named after their title; the URL uses its slug:
#   "Disabling slack's autoupdates on macOS" -> disabling-slack-s-autoupdates-on-macos
# CEILING: ASCII only, so a title with é or emoji loses those characters.
# Transliterate before slugging if a title ever needs them.
slug_awk='function slug(s) { s = tolower(s); gsub(/[^a-z0-9]+/, "-", s); gsub(/^-+|-+$/, "", s); return s }'
slug() { LC_ALL=C gawk -v s="$1" "${slug_awk}"' BEGIN { print slug(s) }'; }

# Every file in the vault, vault-relative, for resolving wikilinks by name.
vault_files="$(cd "${vault}" && find . -type f -not -path './.*' | sed 's#^\./##')"

# Print $1 (in section $2) with its links to other pages turned into site
# paths. Wikilinks first become the markdown links Obsidian would write:
#   [[Foo Bar]] [[Foo Bar#Heading|text]] -> [Foo Bar](../notes/Foo%20Bar.md) ...
#   ![[x.png]] ![[x.png|alt]]            -> ![](../attachments/x.png) ...
# then links to notes and posts get the page's slug:
#   ../notes/Foo%20Bar.md#frag           -> /notes/foo-bar/#frag
#   Foo%20Bar.md / ./Foo%20Bar.md        -> /notes/foo-bar/ (by name, like
#                                           Obsidian's shortest-path links)
# Attachment links stay vault-relative for the image step below.
# Frontmatter, fenced code and inline code are left alone (bash uses [[ ]]).
# A page without a title: gets its file name, which is its title in the vault.
# Fails on links it can't convert: unknown pages and embedded notes.
site_links() {
    # CEILING: names resolve like Obsidian's (path, then file name), but a
    # name that exists in two folders resolves to whichever find lists
    # first. Filenames are unique in practice; prefer notes/ and posts/ in
    # the lookup if that changes.
    LC_ALL=C gawk -v src="${1#"${vault}"/}" -v section="$2" -v title="$(basename "$1" .md)" "${slug_awk}"'
        function enc(s) { gsub(/ /, "%20", s); return s }
        function dec(s,    out) {
            out = ""
            while (match(s, /%[0-9A-Fa-f][0-9A-Fa-f]/)) {
                out = out substr(s, 1, RSTART - 1) sprintf("%c", strtonum("0x" substr(s, RSTART + 1, 2)))
                s = substr(s, RSTART + 3)
            }
            return out s
        }
        function site(s,    out, t, a, sec, f) {
            out = ""
            while (match(s, /\]\([^)]+\)/)) {
                out = out substr(s, 1, RSTART + 1)
                t = substr(s, RSTART + 2, RLENGTH - 3)
                s = substr(s, RSTART + RLENGTH)
                if (match(t, /^(\.\.\/(notes|posts)\/|(\.\/)?)([^:\/#]+)\.md(#.*)?$/, a)) {
                    sec = a[2]
                    if (sec == "") {
                        f = resolve(dec(a[4]) ".md")
                        sec = f ~ /^(notes|posts)\// ? substr(f, 1, 5) : section
                    }
                    t = "/" sec "/" slug(dec(a[4])) "/" a[5]
                }
                out = out t ")"
            }
            return out s
        }
        function resolve(t,    b) {
            if (t in path) return t
            if ((t ".md") in path) return t ".md"
            b = t; sub(/.*\//, "", b)
            if (b in byname) return byname[b]
            if ((b ".md") in byname) return byname[b ".md"]
            return ""
        }
        function warn(msg) {
            printf "\033[0;33m%s in %s\033[0m\n", msg, src > "/dev/stderr"
            bad = 1
        }
        function convert(s,    out, m, embed, inner, alias, frag, p, file, text) {
            out = ""
            while (match(s, /!?\[\[[^]]+\]\]/)) {
                m = substr(s, RSTART, RLENGTH)
                out = out substr(s, 1, RSTART - 1)
                s = substr(s, RSTART + RLENGTH)
                embed = substr(m, 1, 1) == "!"
                inner = substr(m, embed ? 4 : 3, length(m) - (embed ? 5 : 4))
                alias = ""
                # Obsidian escapes the pipe as \| inside tables.
                if (match(inner, /\\?\|/)) {
                    alias = substr(inner, RSTART + RLENGTH)
                    inner = substr(inner, 1, RSTART - 1)
                }
                frag = ""
                if ((p = index(inner, "#")) > 0) {
                    frag = substr(inner, p)
                    inner = substr(inner, 1, p - 1)
                }
                file = inner == "" ? "" : resolve(inner)
                if (inner != "" && file == "") {
                    warn("Unresolved wikilink " m); out = out m; continue
                }
                if (embed && file ~ /\.md$/) {
                    warn("Unsupported note embed " m); out = out m; continue
                }
                if (embed) {
                    if (file !~ /^attachments\//) warn("Embed outside attachments/ " m)
                    # ![[x.png|300]] and |300x200 set a size, not alt text.
                    if (alias ~ /^[0-9]+(x[0-9]+)?$/) alias = ""
                    out = out "![" alias "](../" enc(file) ")"
                    continue
                }
                text = alias
                if (text == "") { text = inner; sub(/\.md$/, "", text); sub(/.*\//, "", text) }
                if (text == "") text = substr(frag, 2)
                out = out "[" text "](" (file == "" ? "" : "../" enc(file)) enc(frag) ")"
            }
            return out s
        }
        FNR == NR {
            path[$0] = 1
            b = $0; sub(/.*\//, "", b)
            if (!(b in byname)) byname[b] = $0
            next
        }
        FNR == 1 && /^---$/ { front = 1; print; next }
        front {
            if (/^title:/) titled = 1
            # Obsidian file names cannot contain " or \, so quoting is safe.
            if (/^---$/) { front = 0; if (!titled) print "title: \"" title "\"" }
            print; next
        }
        /^[ \t]*(```|~~~)/ { fence = !fence; print; next }
        fence { print; next }
        {
            # CEILING: splits on single backticks, so a ``span with ` in it``
            # is misread. Fine for how these pages use inline code.
            n = split($0, seg, "`")
            line = ""
            for (i = 1; i <= n; i++) line = line (i > 1 ? "`" : "") (i % 2 ? site(convert(seg[i])) : seg[i])
            print line
        }
        END { exit bad }
    ' <(printf '%s\n' "${vault_files}") "$1"
}

broken=0
count=0
declare -A slugs
for section in notes posts; do
    dst="${repo_root}/content/${section}"
    find "${dst}" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

    for src in "${vault}/${section}"/*.md; do
        [[ -e "${src}" ]] || continue
        is_published "${src}" || continue

        name="$(slug "$(basename "${src}" .md)")"
        if [[ -n "${slugs[${section}/${name}]:-}" ]]; then
            printf "\e[0;33mSlug %s of %s is taken by %s\e[0m\n" "${name}" "${src#"${vault}"/}" "${slugs[${section}/${name}]}" >&2
            broken=1
            continue
        fi
        slugs[${section}/${name}]="${src#"${vault}"/}"

        bundle="${dst}/${name}"
        mkdir -p "${bundle}"
        page="${bundle}/index.md"
        md="$(site_links "${src}" "${section}")" || broken=1

        # ../attachments/x.png -> x.png, now in the bundle.
        sed -E 's#\]\(\.\./attachments/#](#g' <<<"${md}" >"${page}"

        # Images live in the vault's attachments/; bundle the ones this page
        # uses. Photos and screenshots become WebP at most 2000px wide (the
        # theme serves up to 1320w) with metadata such as GPS stripped.
        # Obsidian percent-encodes spaces in markdown links.
        { grep -oE '\]\(\.\./attachments/[^) ]+' <<<"${md}" || true; } |
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
while IFS=: read -r file target; do
    if [[ ! -d "${repo_root}/content/${target}" ]]; then
        printf "\e[0;33mUnpublished link target %s in %s\e[0m\n" "${target}" "${file#"${repo_root}"/}" >&2
        broken=1
    fi
done < <(grep -roE '\]\(/(notes|posts)/[^/)#]+/' "${repo_root}/content/notes" "${repo_root}/content/posts" |
    sed -E 's#^(.*):\]\(/(.*)/$#\1:\2#')

# Links into other vault folders (wiki/, projects/, ...) aren't rewritten
# and would 404 as well. URLs are skipped: they contain a colon.
while IFS=: read -r file link; do
    printf "\e[0;33mUnconverted vault link %s in %s\e[0m\n" "${link}" "${file#"${repo_root}"/}" >&2
    broken=1
done < <(grep -roE '\]\([^):]+\.md(#[^)]*)?\)' "${repo_root}/content/notes" "${repo_root}/content/posts")

printf "\e[1;92mPublished %d pages from %s\e[0m\n" "${count}" "${vault}"
[[ ${broken} == 0 ]] || exit 1
