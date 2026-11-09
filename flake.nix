{
  inputs = {
    agent-skills = {
      url = "path:./nix/agent-skills";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mocword.url = "github:blyoa/nix-mocword";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      agent-skills,
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

        inherit (inputs) mocword;

        editorTools = with pkgs; [
          go
          gopls
          lua-language-server
          mocword.packages.${system}.default
          ripgrep
          stylua
          tree-sitter
        ];

        # plugin builds that run `nix build` use the nix that started the app
        pluginBuildTools =
          with pkgs;
          [
            git
            gnumake
            inputs.neovim-nightly-overlay.packages.${system}.default
            stdenv.cc
          ]
          ++ editorTools;

        minimal = pkgs.writeShellApplication {
          name = "nvim-minimal";
          runtimeInputs = pluginBuildTools;
          text = ''
            root="''${XDG_CACHE_HOME:-$HOME/.cache}/nvimrc-minimal"
            export XDG_CONFIG_HOME="$root/config"
            export XDG_DATA_HOME="$root/data"
            export XDG_STATE_HOME="$root/state"
            export XDG_CACHE_HOME="$root/cache"
            export GOPATH="$root/go"
            export GOCACHE="$root/go-build"

            # lazy.nvim writes lazy-lock.json next to the config, so the config cannot stay in the store
            rm -rf "$XDG_CONFIG_HOME"
            mkdir -p "$XDG_CONFIG_HOME"
            cp -R ${self} "$XDG_CONFIG_HOME/nvim"
            chmod -R u+w "$XDG_CONFIG_HOME/nvim"

            # lazy.nvim keeps existing clones at their commit, and the goda-cmp binary embeds its Go config
            if [ "$(cat "$root/installed" 2>/dev/null || true)" != "${self}" ]; then
              nvim --headless "+Lazy! restore" "+Lazy! build goda-cmp" +qa
              echo "${self}" > "$root/installed"
            fi

            exec nvim "$@"
          '';
        };

        lazyUpdate = pkgs.writeShellApplication {
          name = "lazy-update";
          runtimeInputs = pluginBuildTools;
          text = ''
            nvim -l ${./scripts/lazy-cooldown.lua}
            nvim --headless "+Lazy! restore" +qa
          '';
        };
      in
      {
        nput = {
          inherit (inputs.agent-skills.nput.${system}) skills;
        };

        apps = {
          default = {
            type = "app";
            program = pkgs.lib.getExe minimal;
            meta.description = "Neovim with this config, isolated from the user's XDG directories";
          };
          lazy-update = {
            type = "app";
            program = pkgs.lib.getExe lazyUpdate;
            meta.description = "Update lazy-lock.json within the 7-day cooldown and restore the plugins";
          };
        };

        devShells =
          let
            inherit (self.checks.${system}.git-hooks) shellHook enabledPackages;
          in
          {
            default = pkgs.mkShell {
              inputsFrom = [
                agent-skills.devShells.${system}.default
              ];
              inherit shellHook;
              packages = editorTools ++ enabledPackages;
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
