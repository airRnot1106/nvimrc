{
  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stop-slop = {
      url = "github:hardikpandya/stop-slop";
      flake = false;
    };
  };

  outputs =
    {
      agent-skills,
      mattpocock-skills,
      nixpkgs,
      stop-slop,
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
      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          agentLib = agent-skills.lib.agent-skills;
          sources = {
            mattpocock-skills = {
              path = mattpocock-skills;
              subdir = "skills";
            };
            stop-slop = {
              path = stop-slop;
            };
          };
          catalog = agentLib.discoverCatalog sources;
          allowlist = agentLib.allowlistFor {
            inherit catalog sources;
            enable = [ "stop-slop" ];
          };
          selection = agentLib.selectSkills {
            inherit catalog allowlist sources;
            skills = {
              grill-me = {
                from = "mattpocock-skills";
                path = "productivity/grill-me";
              };
              grilling = {
                from = "mattpocock-skills";
                path = "productivity/grilling";
              };
              handoff = {
                from = "mattpocock-skills";
                path = "productivity/handoff";
              };
            };
          };
          bundle = agentLib.mkBundle { inherit pkgs selection; };
          localTargets = {
            claude = agentLib.defaultLocalTargets.claude // {
              enable = true;
            };
          };
        in
        {
          default = pkgs.mkShellNoCC {
            shellHook = agentLib.mkShellHook {
              inherit pkgs bundle;
              targets = localTargets;
            };
          };
        }
      );
    };
}
