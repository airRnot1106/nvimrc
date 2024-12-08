local create_user_command = vim.api.nvim_create_user_command

create_user_command("YankRelativePath", function()
    local relative_path = vim.fn.fnamemodify(vim.fn.expand "%:p", ":~:.")
    vim.fn.setreg("+", relative_path)
    vim.fn.setreg('"', relative_path)
    print("Yanked: " .. relative_path)
end, { desc = "Yank the relative path of the current buffer to clipboard" })
