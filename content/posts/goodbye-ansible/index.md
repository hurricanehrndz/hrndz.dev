---
# vim: set ft=markdown tw=72:
date: 2020-12-24T08:00:00-0700
lastmod: 2020-12-24T08:00:00-0700
draft: false
publish: true
aliases: [/posts/88ivmekw/]
description: Hello nix and NixOS, Goodbye Anislbe!
tags: [nix, nixos, ansible]
title: "Goodbye Ansible"
---

Today I formally part ways with Ansible. Well, not really. Ansible is so
pervasive within the configuration management space that there is no
avoiding it. So, I will be seeing you (Ansible) professionally only. For
my own personal configuration management needs, I am embracing Nix.

Yes, I have been taking [Nix pills][nix-pills], and if you are thinking
that it has affected my decision making, you are not wrong. One of those
very said Pills states, _"in the Nix world all existing self-containment
and orchestration tools are deprecated"_, who could walk away
unaffected? After all, that is one bold statement, and I will be putting
it to the test in the next couple of weeks.

First impressions lead me to believe they are putting their money where
their mouth is! For example, below is a simple configuration to install
a clean OS, create a user, set the user's default editor to VIM.

```nix
{ config, pkgs, ... }:

let
  hostName = "HAL9000";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Set localization and tty options
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set the timezone
  time.timeZone = "America/Edmonton";

  networking = {
    inherit hostName;
    networkmanager.enable = true;
  };

  programs.zsh.enable = true;
  programs.vim.defaultEditor = true;

  users = {
    # Shell is set to zsh for all users as default.
    defaultUserShell = pkgs.zsh;

    users.hurricanehrndz = {
      isNormalUser = true;
      home = "/home/hurricanehrndz";
      description = "Carlos Benito Hernandez";
      extraGroups = [ "wheel" "networkmanager" "audio" ];
      shell = pkgs.zsh;

      # Public ssh-keys that are authorized for the user. Fetched from homepage
      # and github profile.
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl { url = "https://github.com/hurricanehrndz.keys"; })
      ];
    };
  };
}
```

The Nix language's declarative nature makes the above configuration very
legible, even for those unfamiliar with it. The sheer fact that so much
can be accomplished with a mere 48 lines of code is beautiful and so
captivating. In contrast, achieving a similar outcome with Ansible
becomes an ordeal.

One could try to find a role within the Ansible-Galaxy store that
accomplishes something similar. More than likely, you will be left to
your own devices. You will either write a Playbook, develop a custom
role, or perhaps write your own module. The latter will not help Ansible
evolve but rather increase complexity and the uncontrollable growth of
Ansible itself.

This [unmanageable expansion][ansible-restructure] can already be
witnessed as modules that use to be considered a core part of Ansible
have been increasingly migrated to community repositories. In contrast,
the simplicity in Nix offers a reprieve.

I can only surmise this simplicity is born from its functional design.
Nix is a functional language at heart, so complexity is created from the
composition of simple functions rather than the never-ending extension
of the software. So, as [Brain Beckman][brain-youtube] said, it seems
_"the way to control complexity is from compositionality"_.

Stay tuned, as I go deeper into Nix and NixOS in the upcoming weeks.

[ansible-restructure]: https://www.ansible.com/blog/thoughts-on-restructuring-the-ansible-project
[brain-youtube]: https://youtu.be/ZhuHCtR3xq8
[nix-pills]: https://nixos.org/guides/nix-pills/index.html
