{
  projectRootFile = "flake.nix";
  programs = {
    deno.enable = true;
    nixfmt.enable = true;
    oxfmt = {
      enable = true;
      includes = [
        "*.cjs"
        "*.graphql"
        "*.hbs"
        "*.json5"
        "*.mdx"
        "*.mjs"
        "*.mustache"
        "*.toml"
        "*.vue"
      ];
    };
    stylua.enable = true;
  };
}
