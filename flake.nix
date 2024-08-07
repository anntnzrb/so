{
  description = "annt's sandbox for ccpg1056";

  nixConfig = {
    extra-trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    extra-substituters = [ "https://devenv.cachix.org" ];
  };

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";

    # src tree fmt
    treefmt-nix.url = "github:numtide/treefmt-nix/main";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # devenv
    devenv.url = "github:cachix/devenv";
    devenv-root.url = "file+file:///dev/null";
    devenv-root.flake = false;
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  outputs = inputs@{ flake-parts, devenv-root, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = with inputs; [
        devenv.flakeModule
        treefmt-nix.flakeModule
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, pkgs, ... }: {
        devenv.shells.default = {
          name = "annt-devenv-template";

          devenv.root =
            let
              devenvRootFileContent = builtins.readFile devenv-root.outPath;
            in
            pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

          languages = {
            nix.enable = true;
            c.enable = true;
          };

          devcontainer = {
            enable = true;
            settings = {
              image = "ghcr.io/cachix/devenv:latest";
              updateContentCommand = "direnv reload";
              customizations.vscode.extensions = [
                "mkhl.direnv"
                "jnoortheen.nix-ide"

                "tomoki1207.pdf"

                "ms-vscode.cpptools-extension-pack"
                "ms-vscode.makefile-tools"
              ];
            };
          };

          packages = with pkgs; [
            config.treefmt.build.wrapper

            # C
            clang

            # typst
            typst
            typst-lsp
            typstfmt
          ];
        };

        treefmt.config = {
          projectRootFile = "flake.nix";
          programs = {
            nixpkgs-fmt.enable = true;
            prettier.enable = true;
            clang-format.enable = true;
          };
          settings.formatter."typstfmt" = {
            command = "${pkgs.typstfmt}/bin/typstfmt";
            includes = [ "*.typ" ];
          };
        };
      };
    };
}
