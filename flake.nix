{
  description = "OpenAI ChatGPT desktop app for Linux and macOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
  in {
    packages = nixpkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      chatgpt =
        if system == "aarch64-darwin"
        then pkgs.chatgpt
        else pkgs.callPackage ./package.nix {};
    in {
      inherit chatgpt;
      default = chatgpt;
    });
  };
}
