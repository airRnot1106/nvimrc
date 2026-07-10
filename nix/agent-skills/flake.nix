{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nput.url = "github:yasunori0418/nput";

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    stop-slop = {
      url = "github:hardikpandya/stop-slop";
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
            name,
            src,
            subpath,
          }:
          {
            name = ".claude/skills/${name}";
            value = { inherit src subpath; };
          };

        skills =
          let
            inherit (inputs) mattpocock-skills stop-slop;
          in
          [
            {
              name = "grill-me";
              src = mattpocock-skills;
              subpath = "skills/productivity/grill-me";
            }
            {
              name = "grilling";
              src = mattpocock-skills;
              subpath = "skills/productivity/grilling";
            }
            {
              name = "handoff";
              src = mattpocock-skills;
              subpath = "skills/productivity/handoff";
            }
            {
              name = "stop-slop";
              src = stop-slop;
              subpath = ".";
            }
          ];
      in
      {
        nput.skills = nput.lib.mkManifest {
          inherit pkgs;
          root = nput.lib.projectRoot;
          entries = builtins.listToAttrs (map mkEntry skills);
        };

        devShells.default = pkgs.mkShellNoCC {
          packages = [ nput.packages.${system}.nput ];
          shellHook = "nput apply skills --no-wait";
        };
      }
    );
}
