local keymap = vim.api.nvim_set_keymap

-- leader
vim.g.mapleader = " "

-- mode
keymap("i", "jj", "<Esc>", { noremap = true, silent = true })

-- cursor
keymap("n", "k", "gk", { noremap = true, silent = true })
keymap("n", "j", "gj", { noremap = true, silent = true })
keymap("", "K", "10k", { noremap = true, silent = true })
keymap("", "J", "10j", { noremap = true, silent = true })
keymap("", "H", "0", { noremap = true, silent = true })
keymap("", "<C-h>", "^", { noremap = true, silent = true })
keymap("", "L", "$", { noremap = true, silent = true })

-- edit
keymap("", "x", '"_x', { noremap = true, silent = true })
keymap("", "X", '"_X', { noremap = true, silent = true })
keymap("", "s", '"_s', { noremap = true, silent = true })
keymap("", "S", '"_S', { noremap = true, silent = true })
keymap("", "c", '"_c', { noremap = true, silent = true })
keymap("", "C", '"_C', { noremap = true, silent = true })
keymap("n", "dd", '"_dd', { noremap = true, silent = true })
keymap("n", "D", '"_D', { noremap = true, silent = true })
keymap("n", "<C-d>", "dd", { noremap = true, silent = true })
keymap("x", "d", '"_d', { noremap = true, silent = true })
keymap("x", "D", '"_D', { noremap = true, silent = true })
keymap("x", "<C-d>", "d", { noremap = true, silent = true })

-- buffer
keymap("", "<Leader>w", ":w<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>[", ":bprev<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>]", ":bnext<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>d", ":bd<CR>", { noremap = true, silent = true })

-- window
keymap("n", "<Leader>gs", ":split<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>gv", ":vsplit<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>gh", "<C-w>h", { noremap = true, silent = true })
keymap("n", "<Leader>gj", "<C-w>j", { noremap = true, silent = true })
keymap("n", "<Leader>gk", "<C-w>k", { noremap = true, silent = true })
keymap("n", "<Leader>gl", "<C-w>l", { noremap = true, silent = true })
keymap("n", "<Leader>gw", "<C-w>w", { noremap = true, silent = true })
keymap("n", "<Leader>gW", "<C-w>W", { noremap = true, silent = true })
keymap("n", "<Leader>gd", "<C-w>c", { noremap = true, silent = true })
keymap("n", "<Leader>gto", "<C-w>o", { noremap = true, silent = true })

-- filer
keymap("n", "<Leader>e", ":lua MiniFiles.open()<CR>", { noremap = true, silent = true })

-- apprearance
keymap("n", "<Esc><Esc>", ":nohlsearch<CR>", { noremap = true, silent = true })

-- telescope
keymap("n", "<Leader>tff", "<Cmd>Telescope find_files<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tfg", "<Cmd>Telescope live_grep<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tgs", "<Cmd>Telescope git_status<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tgl", "<Cmd>Telescope git_commits<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tfb", "<Cmd>Telescope buffers<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tfo", "<Cmd>Telescope oldfiles<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tfv", "<Cmd>Telescope vim_options<CR>", { noremap = true, silent = true })
keymap("n", "<Leadder>tfk", "<Cmd>Telescope keymaps<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>tfr", "<Cmd>Telescope registers<CR>", { noremap = true, silent = true })
