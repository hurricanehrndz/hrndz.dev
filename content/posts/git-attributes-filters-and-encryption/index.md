---
# vim: set ft=markdown tw=72:
date: 2025-02-26T21:03:34-0700
lastmod: 2025-03-02T20:14:48-0700
draft: false
publish: true
aliases: [/posts/r4621ixh/]
tags: [encryption, git]
title: "Git Attributes, Filters, and Encryption"
---

The [Git documentation][gitbook-doc] states the following about
`.gitattributes`:

- Attributes can be used to filter content before checking it into or
  out of Git.
- Smudge filters are applied on checkout.
- Clean filters are applied at check-in.
- `clean -> clean` should produce the same result as `clean`.[^1]
- `smudge -> smudge -> clean` should be the same as `clean`.[^1]

Most of these statements are true, albeit a bit misleading. Things
change when you run `git status`.

When `git status` is executed, Git needs to compare the working tree
with the index. For this comparison to be valid, an apples-to-apples
comparison must take place. This usually means that data transformations
(filters) need to be applied.[^2]

This might be a little confusing at first, but it becomes clearer when
looking at concrete examples, such as handling secrets and encryption.
Before diving into that, though, let's get a basic understanding of
Git's inner workings.

## The Three Trees in Git

What follows is an oversimplification of some of Git's basic mechanics,
particularly the three trees. According to the documentation, Git
manages and manipulates three trees, which are essentially collections
of files:

| Tree         | Role                      |
| ------------ | ------------------------- |
| HEAD         | Last committed state      |
| Index        | Proposed next commit      |
| Working tree | Current working directory |

For the purpose of understanding filters, the index initially contains
references for each content piece stored in HEAD. Besides content, both
HEAD and the index store metadata such as the last modified date and the
SHA-1 sum of the content.

If you want to dive deeper into Git's HEAD, index, and working tree,
here are some great resources:

- [Git Deep Dive - Part 3](https://dev.to/kenakamu/git-deep-dive-part-3-head-index-and-working-tree-3oim)
- [Git Reset Demystified](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified)

## How Filters Affect `git status`

The last modified time is used to speed up the process of determining
differences between the working tree and the index. Normally,
`git status` skips comparing files if the working tree copy is older
than the index, assuming they are identical.

However, when the working copy is newer, Git compares the SHA-1 hashes
of the files. But what happens when filters come into play?

All files stored in trees other than the working tree are "clean",
meaning they have been processed by the clean filter. Let's assume our
clean filter is:

```console
age --encrypt -R ~/.ssh/id_ed25519.pub -
```

This means files in the index and HEAD are stored in an encrypted
format. But what happens when you decrypt and re-encrypt using `age`?

Since `age` leverages modern cryptographic schemes and algorithms, you
end up with two completely different encrypted outputs. Even though the
actual content remains the same, Git though, cannot verify they are
actually equal due to the filter's non-deterministic nature.

This little quirk, often overlooked, is the root cause of many issues on
GitHub. It's something I once knew, forgot, and had to relearn.

Some related discussions and issues:

- [Use age as a clean/smudge filter](https://github.com/FiloSottile/age/discussions/507)
- [SOPS: Use with git-filter config - filter.*.clean and filter.*.smudge](https://github.com/getsops/sops/issues/1137)

So, how does one go about developing a filter that employs
non-deterministic encryption?

## Developing Git attribute filters for non-deterministic encryption

Comparing apples to apples, if we can not compare encrypted content to
encrypted content. Then we must rely on an approach that compares
unencrypted content to unencrypted content.

For those unaware, filters should exclusively operate on `stdin` and
`stdout`. So Git will feed our filter the unencrypted content residing
in our work tree on `stdin`, and the filters responsibility is to spit
out the transformed content on `stdout`.[^1]

While a filter can accept a file path (%f) as an argument, it should
never directly access the file. Instead, the file path should only be
used to help determine what content to write on `stdout`.

The following script wraps `age` to create a filter that does just that.
It accepts the path of the content being operated on, decrypts the
content in HEAD, and compares it to the content received on `stdin`. If
there is no difference between the versions, it publishes the encrypted
content from HEAD to `stdout`. This satisfies one of the tenets of Git
attributes: that smudge -> smudge -> clean be the same as clean.

{{< alert >}} **Warning!** This is a Proof of Concept, not a complete
solution. {{< /alert >}}

```sh
#!/usr/bin/env -S bash -euo pipefail
# based on: https://github.com/getsops/sops/issues/1137#issuecomment-1312640992

AGE_FILE_MARKER="-----BEGIN AGE ENCRYPTED FILE-----"

# we need $2 to be the path of the file so we can check the previous version
# via git-show to prevent the encryption's non-determinism from resulting in
# unnecessary changes
if test $# -ne 2; then
    echo "Usage: $0 {enc,dec} FILE" >&2
    exit 1
fi
op="$1"
fpath="$2"

# check for required variables
if [[ -z "$AGE_KEY_PATH" || -z "$AGE_RECIPIENT" ]]; then
    echo "Environment missing AGE_KEY_PATH, and/or AGE_RECIPIENT " >&2
    exit 1
fi

# must satisfy
# clean -> clean == clean
# smudge -> smudge --> clean == clean
function enc {
    if ! git cat-file -e "HEAD:$fpath" &>/dev/null; then
        # if git cat-file -e fails, then the file doesn't exist at HEAD, so it's new,
        # meaning we need to encrypt it for the first time
        echo "$0: no previous version found while cleaning $fpath" >&2
        age --encrypt -a -r "$AGE_RECIPIENT" "$tmpfile"
    elif diff <(git cat-file -p "HEAD:$fpath" | age --decrypt -i "$AGE_KEY_PATH" /dev/stdin) \
        "$tmpfile" >/dev/null; then
        # if there's no difference between the decrypted version of the file at HEAD
        # and the new contents, then we reuse the previous version to prevent
        # unnecessary file updates
        echo "$0: no changes found while cleaning $fpath" >&2
        git cat-file -p "HEAD:$fpath"
    else
        # if there is a difference then we re-encrypt it from tmpfile, where we
        # duplicated stdin to
        echo "$0: found changes while cleaning $fpath" >&2
        age --encrypt -a -r "${AGE_RECIPIENT}" "$tmpfile"
    fi
}

function dec {
    age --decrypt -i "$AGE_KEY_PATH" "$tmpfile"
}

# make sure file gets remove, do not leak secrets
trap 'rm -f "$tmpfile"' EXIT INT TERM HUP

# save /dev/stdin to temporary file
tmpfile=$(mktemp)
cat /dev/stdin > "$tmpfile"

if [[ "$op" == "enc" ]]; then
    # is file already encrypted
    if [[ "$(head -1 "$tmpfile")" == "$AGE_FILE_MARKER" ]]; then
        echo "$0: file already encrypted $fpath" >&2
        cat "$tmpfile"
        exit 0
    fi
    enc
fi

if [[ "$op" == "dec" ]]; then
    # is file already decrypted
    if [[ "$(head -1 "$tmpfile")" != "${AGE_FILE_MARKER}" ]]; then
        echo "$0: file already decrypted $fpath" >&2
        cat "$tmpfile"
        exit 0
    fi
    dec
fi
```

## Experimenting with the age wrapper

Before proceeding, copy the above script to `~/.local/bin` as
`age-filter.sh`, and ensure the file is executable. Also, ensure you
have created an `age` key.

Create an age key:

```console
age-keygen -o ~/key.txt
```

Configure age environment vars:

```console
export AGE_KEY_PATH="$HOME/key.txt"
export AGE_RECIPIENT=$(awk -F': ' '/# public key:/{print $2}' "$AGE_KEY_PATH")
```

Create a new repo:

```console
mkdir age-example
cd age-example
git init
echo "# Age Example" > README.md
git add .
git commit -m "Initial commit"
```

Configure our Git attributes and filters:

```console
git config filter.age.clean "age-filter.sh enc %f"
git config filter.age.smudge "age-filter.sh dec %f"
git	config filter.age.required true
cat <<EOF >>.gitattributes
secrets/** filter=age
EOF
git add .
git commit -m "Adding gitattributes"
```

Add some secret content:

```console
mkdir -p secrets
echo "super secret password" > secrets/sensitive.txt
git add secrets/
git commit -m "Adding some sensitive data"
```

Confirm data is encrypted in HEAD:

```console
git show HEAD:secrets/sensitive.txt
```

Confirm status reports no changes:

```console
rm -f secrets/sensitive.txt
git checkout --force -- secrets/sensitive.txt
git status
```

## Key Takeaways

Git attributes and filters are challenging, and my hope is that I have
captured some hard-learned lessons. Also, let's acknowledge that
sometimes documentation, blogs, and other resources can be misleading.

As a matter of fact, I have misled you. For one, although it is best
practice to smudge and clean using only `stdin` and `stdout`, it is not
the only way.

About two years ago, I had the opportunity to refactor[^3] a Git filter
known as [GitFat][gh-gitfat]. One of the key improvements in my
implementation was moving away from `stdin` and `stdout`. By leveraging
my understanding of Git's internals, I was able to
[smudge files outside of Git][gitfat-perf-patch] much more efficiently.

Hopefully, someone else finds all this intriguing and beneficial. I know
I will, especially next time I find myself working with Git filters.
Instead of relearning all these lessons again, I only need to reference
my own notes.

## Other Notable Resources

- [Why is git clone non-deterministic?](https://stackoverflow.com/questions/76670052/why-is-git-clone-non-deterministic)

[gh-gitfat]: https://github.com/jedbrown/git-fat
[gitbook-doc]: https://git-scm.com/book/ms/v2/Customizing-Git-Git-Attributes
[gitfat-perf-patch]: https://github.com/hurricanehrndz/git-fat/commit/fd4b2616ee654cdfc06b49ca5d7d75196bcdf490
[^1]: https://git-scm.com/docs/gitattributes
[^2]: https://stackoverflow.com/questions/41934945/why-does-git-status-run-filters
[^3]: https://github.com/hurricanehrndz/git-fat/commit/fd4b2616ee654cdfc06b49ca5d7d75196bcdf490#diff-d9957c5376a609a53e152e3eb8deadf16e264d78d860d47c8d0e62811ea087ddR269
