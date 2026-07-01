local keymap = vim.keymap.set
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- appearance
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.laststatus = 2
vim.opt.showtabline = 2
vim.opt.cmdheight = 1
vim.opt.scrolloff = 12
vim.opt.termguicolors = true

autocmd("TextYankPost", {
    pattern = "*",
    group = augroup("highlight_yank", {}),
    callback = function()
        vim.hl.hl_op { higroup = "IncSearch", timeout = 200 }
    end,
})

-- indent
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- movement
vim.opt.wrap = true
vim.opt.whichwrap = "b,s,h,l,[,],<,>,~"

keymap("", "k", "gk", { silent = true, desc = "Move up by display line" })
keymap("", "j", "gj", { silent = true, desc = "Move down by display line" })
keymap("", "K", "10gk", { silent = true, desc = "Move up 10 display lines" })
keymap("", "J", "10gj", { silent = true, desc = "Move down 10 display lines" })
keymap("", "H", "0", { silent = true, desc = "Go to line start" })
keymap("", "L", "$", { silent = true, desc = "Go to line end" })

-- editing
vim.opt.virtualedit = "block"
vim.opt.showmatch = true

keymap("i", "jj", "<Esc>", { silent = true, desc = "Exit insert mode" })
keymap("n", "<C-d>", "dd", { silent = true, desc = "Delete line" })
keymap("x", "<C-d>", "d", { silent = true, desc = "Delete selection" })

-- clipboard
vim.opt.clipboard:append "unnamedplus"

keymap({ "n", "x" }, "x", '"_x', { silent = true, desc = "Delete char without yank" })
keymap({ "n", "x" }, "s", '"_s', { silent = true, desc = "Substitute without yank" })
keymap({ "n", "x" }, "c", '"_c', { silent = true, desc = "Change without yank" })
keymap({ "n", "x" }, "d", '"_d', { silent = true, desc = "Delete without yank" })
keymap("n", "C", '"_C', { silent = true, desc = "Change to line end without yank" })
keymap("n", "D", '"_D', { silent = true, desc = "Delete to line end without yank" })
keymap("n", "S", '"_S', { silent = true, desc = "Substitute line without yank" })
keymap("x", "p", '"_dP', { silent = true, desc = "Paste without yank" })

-- search
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })
keymap("n", "*", "*N", { silent = true, desc = "Search word under cursor" })

-- files
vim.opt.fileencoding = "utf-8"
vim.opt.swapfile = false

keymap("", "<Leader>w", ":w<CR>", { silent = true, desc = "Save file" })

-- misc
vim.opt.mouse = ""
vim.opt.wildoptions = "fuzzy"
vim.opt.helplang = "ja"
vim.opt.updatetime = 500
