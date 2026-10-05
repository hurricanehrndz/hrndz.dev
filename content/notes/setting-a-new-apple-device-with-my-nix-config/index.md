---
# vim: set ft=markdown tw=72:
date: 2025-03-03T13:49:16-0700
lastmod: 2025-03-03T13:49:16-0700
draft: false
publish: true
aliases: [/notes/yr8m9tt6/]
tags: []
title: "Setting a new Apple Device with my Nix config"
---

## Install Nix via Determinate System Installer

```console
curl \
  --proto '=https' \
  --tlsv1.2 \
  -sSf \
  -L https://install.determinate.systems/nix \
  | sh -s -- install
```

Answer `no` when prompted to "Install Determinate Nix".

## Install macOS Developer Tools

```console
xcode-select --install
```

## Setup Agenix/Age/Strongbox Identity

TODO: Invetigate using YubiKey

- Download SOPS' AGE Key from 1Password place in
  `$HOME/.config/sops/age/keys.txt`

- Link Strongbox identity

  ```console
  ln -sf  "$HOME/.config/sops/age/keys.txt" \
      "$HOME/.strongbox_identity"
  ```

## Get Nix Config on the new System

```console
mkdir -p "$HOME/src/me/"
git clone https://github.com/hurricanehrndz/nixcfg "$HOME/src/me/nixcfg"
```

## Start development shell

```console
cd $HOME/src/me/nixcfg
nix develop
```

## Smudge encrypted content

```console
rm {file}
git checkout --force -- {file}
```

## Create system ssh keys

```console
sudo /usr/libexec/sshd-keygen-wrapper
```

Wait a couple of seconds and then cancel and/or kill the process

## Update system secrets.nix with new key

```console
cat /etc/ssh/ssh_host_ed25519_key.pub | pbcopy
vi secrets/secrets.nix
```

In secrets/secrets.nix either update the key for existing hostname or
added it accordingly. Then proceed to re-keying:

```console
pushd secrets
agenix --rekey
popd
```

## Build Darwin system and switch

Before proceeding ensure terminal has been granted full disk access.
Then proceed to building the system definition:

```console
mkdir $HOME/.config/zsh
mkdir $HOME/.config/mods
nrb .
```
