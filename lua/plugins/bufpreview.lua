return {
    name = "bufpreview",
    repo = "kat0h/bufpreview.vim",
    extAttrs = { installerBuild = "deno task prepare" },
    on_ft = { "markdown" },
}
