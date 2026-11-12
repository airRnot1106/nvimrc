-- An extension rule does not re-sort vim.filetype's patterns as a pattern
-- rule does, and wrapping the preload keeps vim.filetype from loading during
-- startup before any file is opened.
local function yaml(path)
    return path:find "/%.github/workflows/" and "yaml.ghactions" or "yaml"
end

local function register(filetype)
    filetype.add { extension = { yml = yaml, yaml = yaml } }
end

local preload = package.preload["vim.filetype"]
if package.loaded["vim.filetype"] or not preload then
    register(vim.filetype)
else
    package.preload["vim.filetype"] = function(...)
        local filetype = preload(...)
        register(filetype)
        return filetype
    end
end
