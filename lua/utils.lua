local M = {}

function M.resolve_local_bin(cmd)
    local bufname = vim.api.nvim_buf_get_name(0)
    local node_modules = vim.fs.find('node_modules', { path = bufname, upward = true })[1]
    if node_modules then
        local root = vim.fs.dirname(node_modules)
        local bin = vim.fs.joinpath(root, "node_modules", ".bin", cmd)
        if (vim.uv.fs_stat(bin) or {}).type == 'file' then
            return bin
        end
    end
    return cmd
end

function M.has_local_bin(cmd)
    local bufname = vim.api.nvim_buf_get_name(0)
    local node_modules = vim.fs.find('node_modules', { path = bufname, upward = true })[1]
    if node_modules then
        local root = vim.fs.dirname(node_modules)
        local bin = vim.fs.joinpath(root, "node_modules", ".bin", cmd)
        if (vim.uv.fs_stat(bin) or {}).type == 'file' then
            return true
        end
    end
    return false
end

return M
