local keymap = vim.api.nvim_set_keymap

-- leader
vim.g.mapleader = " "

-- mode
keymap("i", "jj", "<Esc>", { noremap = true, silent = true })

-- cursor
keymap("", "k", "gk", { noremap = true, silent = true })
keymap("", "j", "gj", { noremap = true, silent = true })
keymap("", "K", "10gk", { noremap = true, silent = true })
keymap("", "J", "10gj", { noremap = true, silent = true })
keymap("", "H", "0", { noremap = true, silent = true })
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
keymap("v", "p", '"_dP', { noremap = true, silent = true })

-- buffer
keymap("", "<Leader>w", ":w<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>[", "<Cmd>BufferPrevious<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>]", "<Cmd>BufferNext<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>d", "<Cmd>BufferClose<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>to", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>pp", "<Cmd>BufferPick<CR>", { noremap = true, silent = true })
keymap("n", "<Leader>pd", "<Cmd>BufferPickDelete<CR>", { noremap = true, silent = true })

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
keymap("n", "<Leader>e", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>", { noremap = true, silent = true })

-- apprearance
keymap("n", "<Esc><Esc>", ":nohlsearch<CR>", { noremap = true, silent = true })
