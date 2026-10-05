#!/usr/bin/env bash
# Pages are named after their title, which needs no title: of its own, and
# are published under its slug. Links to
# them, wiki or markdown, must reach the site as working links, and bash's
# [[ ]] in code must not. Runs script.sh against a throwaway vault and
# repo: bash flake/packages/publish/test.sh
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
script="$(cd "$(dirname "$0")" && pwd)/script.sh"

mkdir -p "${tmp}"/vault/{notes,posts,attachments,wiki} "${tmp}"/repo/content/{notes,posts}
git -C "${tmp}/repo" init -q
printf 'GIF89a' >"${tmp}/vault/attachments/a pic.gif"
printf -- '---\npublish: true\ntitle: "Other: the page"\n---\n# Other\n' >"${tmp}/vault/notes/Other Page.md"
cat >"${tmp}/vault/posts/A Page!.md" <<'EOF'
---
publish: true
related: "[[Other Page]]"
---
See [[Other Page]], [[Other Page#Some Heading|that bit]], [[#Local]] and `[[code]]`.
Markdown: [other](../notes/Other%20Page.md), [short](Other%20Page.md) and [self](A%20Page!.md#top).
![[a pic.gif|a picture]] ![[a pic.gif|300]]

| [[Other Page\|in a table]] |

```bash
if [[ -z "$x" ]]; then
```
EOF

publish() { (cd "${tmp}/repo" && VAULT="${tmp}/vault" bash "${script}"); }

publish >/dev/null
diff -u - "${tmp}/repo/content/posts/a-page/index.md" <<'EOF'
---
publish: true
related: "[[Other Page]]"
title: "A Page!"
---
See [Other Page](/notes/other-page/), [that bit](/notes/other-page/#Some%20Heading), [Local](#Local) and `[[code]]`.
Markdown: [other](/notes/other-page/), [short](/notes/other-page/) and [self](/posts/a-page/#top).
![a picture](a%20pic.gif) ![](a%20pic.gif)

| [in a table](/notes/other-page/) |

```bash
if [[ -z "$x" ]]; then
```
EOF
[[ -f "${tmp}/repo/content/posts/a-page/a pic.gif" ]]
grep -qx 'title: "Other: the page"' "${tmp}/repo/content/notes/other-page/index.md"
[[ $(grep -c '^title:' "${tmp}/repo/content/notes/other-page/index.md") == 1 ]]

# Links publishing can't honour fail the run instead of shipping dead links.
printf -- '---\npublish: true\n---\n[[missing]] [[wiki-page]] ![[Other Page]]\n' >"${tmp}/vault/notes/bad.md"
printf -- '---\npublish: true\n---\n' >"${tmp}/vault/notes/Other-Page.md"
touch "${tmp}/vault/wiki/wiki-page.md"
if out="$(publish 2>&1)"; then
    echo "expected publish to fail on bad links" >&2
    exit 1
fi
for want in 'Unresolved wikilink [[missing]]' 'Unconverted vault link ](../wiki/wiki-page.md)' 'Unsupported note embed ![[Other Page]]' 'Slug other-page of notes/Other-Page.md is taken by notes/Other Page.md'; do
    grep -qF "${want}" <<<"${out}" || {
        printf 'missing warning: %s\n%s\n' "${want}" "${out}" >&2
        exit 1
    }
done
echo ok
