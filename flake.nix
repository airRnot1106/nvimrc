{
  inputs = {
    agent-skills = {
      url = "path:./nix/agent-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dpp.url = "path:./nix/dpp";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kakehashi.url = "github:atusy/kakehashi";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mocword.url = "github:blyoa/nix-mocword";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      agent-skills,
      dpp,
      flake-utils,
      git-hooks,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        inherit (inputs) kakehashi mocword;
      in
      {
        nput.dpp = dpp.packages.${system}.manifest;

        devShells =
          let
            inherit (self.checks.${system}.git-hooks) shellHook enabledPackages;
          in
          {
            default = pkgs.mkShell {
              inputsFrom = [
                agent-skills.devShells.${system}.default
                dpp.devShells.${system}.default
              ];
              inherit shellHook;
              packages =
                with pkgs;
                [
                  copilot-language-server
                  deno
                  kakehashi.packages.${system}.default
                  lua-language-server
                  mocword.packages.${system}.default
                  ripgrep
                  tree-sitter
                ]
                ++ enabledPackages;
            };
          };

        formatter =
          let
            treefmtEval = treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix;
          in
          treefmtEval.config.build.wrapper;

        checks = {
          git-hooks = git-hooks.lib.${system}.run (
            import ./nix/git-hooks.nix {
              inherit self pkgs;
            }
          );
        };
      }
    );
}
