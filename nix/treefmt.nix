{
  projectRootFile = "flake.nix";
  settings.global.excludes = [ "lazy-lock.json" ];
  programs = {
    deno.enable = true;
    gofmt.enable = true;
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
