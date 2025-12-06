local utils = require "utils"

---@type vim.lsp.Config
return {
    cmd = { utils.resolve_local_bin "oxc_language_server" },
}
