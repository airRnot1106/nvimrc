{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nput.url = "github:yasunori0418/nput";

    denops-vim = {
      url = "github:vim-denops/denops.vim";
      flake = false;
    };
    dpp-vim = {
      url = "github:Shougo/dpp.vim";
      flake = false;
    };
    dpp-ext-installer = {
      url = "github:Shougo/dpp-ext-installer";
      flake = false;
    };
    dpp-ext-lazy = {
      url = "github:Shougo/dpp-ext-lazy";
      flake = false;
    };
    dpp-protocol-git = {
      url = "github:Shougo/dpp-protocol-git";
      flake = false;
    };
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      nput,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        mkEntry =
          {
            repo,
            src,
          }:
          {
            name = ".cache/dpp/repos/github.com/${repo}";
            value = { inherit src; };
          };

        repos =
          let
            inherit (inputs)
              dpp-vim
              dpp-ext-installer
              dpp-ext-lazy
              dpp-protocol-git
              denops-vim
              ;
          in
          [
            {
              repo = "Shougo/dpp.vim";
              src = dpp-vim;
            }
            {
              repo = "Shougo/dpp-ext-installer";
              src = dpp-ext-installer;
            }
            {
              repo = "Shougo/dpp-ext-lazy";
              src = dpp-ext-lazy;
            }
            {
              repo = "Shougo/dpp-protocol-git";
              src = dpp-protocol-git;
            }
            {
              repo = "vim-denops/denops.vim";
              src = denops-vim;
            }
          ];
      in
      {
        nput.dpp = nput.lib.mkManifest {
          inherit pkgs;
          root = nput.lib.homeRoot;
          entries = builtins.listToAttrs (map mkEntry repos);
        };

        devShells.default = pkgs.mkShellNoCC {
          packages = [ nput.packages.${system}.nput ];
          shellHook = "nput apply dpp --no-wait";
        };
      }
    );
}
