# ChatGPT desktop for Nix

Packages OpenAI's official ChatGPT desktop app for x86_64/aarch64 Linux and Apple-silicon macOS. Linux uses version-pinned `.deb` files from [OpenAI's Linux downloads](https://learn.chatgpt.com/docs/linux/linux-app); macOS uses the existing `nixpkgs#chatgpt` package. Intel macOS is not supported.

```sh
nix run github:AJMC2002/chatgpt-nix
```

For NixOS, add the flake as an input, then install its output:

```nix
inputs.chatgpt.url = "github:AJMC2002/chatgpt-nix";

# In a NixOS module with inputs and pkgs in scope:
environment.systemPackages = [
  inputs.chatgpt.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

The Linux package installs `bin/chatgpt`, the vendor's `chatgpt.desktop` under `share/applications`, and its icon under `share/pixmaps`. In KDE it appears under **Utilities**; if the menu hasn't updated after installation, run `kbuildsycoca6 --noincremental` or log out and back in. A desktop *shortcut* in `~/Desktop` is not created automatically.

Nix pins the vendor binary by SHA-256: updating requires changing the version and per-architecture hashes in `package.nix`. The Linux build also patches two bundled plugin-copy sites (and updates ASAR integrity hashes) so the app can edit copies of read-only Nix store resources; `patch-marketplace.mjs` checks the upstream JavaScript hash before patching. The app itself is proprietary OpenAI software; this repository contains only packaging code and does not redistribute the binary. NixOS is not an officially supported Linux distribution for the app, so runtime behavior may differ from OpenAI's supported distributions.
