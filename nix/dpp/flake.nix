{
  inputs = {
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
      nixpkgs,
      nput,
      denops-vim,
      dpp-vim,
      dpp-ext-installer,
      dpp-ext-lazy,
      dpp-protocol-git,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          inherit (nput.packages.${system}) nput;

          manifest = nput.lib.mkManifest {
            inherit pkgs;
            root = nput.lib.homeRoot;
            entries = {
              ".cache/dpp/repos/github.com/Shougo/dpp.vim" = {
                src = dpp-vim;
              };
              ".cache/dpp/repos/github.com/Shougo/dpp-ext-installer" = {
                src = dpp-ext-installer;
              };
              ".cache/dpp/repos/github.com/Shougo/dpp-ext-lazy" = {
                src = dpp-ext-lazy;
              };
              ".cache/dpp/repos/github.com/Shougo/dpp-protocol-git" = {
                src = dpp-protocol-git;
              };
              ".cache/dpp/repos/github.com/vim-denops/denops.vim" = {
                src = denops-vim;
              };
            };
          };
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [ nput.packages.${system}.nput ];
            shellHook = ''
              nput apply dpp --no-wait
            '';
          };
        }
      );
    };
}
