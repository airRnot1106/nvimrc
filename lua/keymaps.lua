local keymap = vim.keymap.set

-- leader
vim.g.mapleader = " "

-- mode
keymap("i", "jj", "<Esc>", { silent = true })

-- cursor
keymap("", "k", "gk", { silent = true })
keymap("", "j", "gj", { silent = true })
keymap("", "K", "10gk", { silent = true })
keymap("", "J", "10gj", { silent = true })
keymap("", "H", "0", { silent = true })
keymap("", "L", "$", { silent = true })

-- edit
keymap("", "x", '"_x', { silent = true })
keymap("", "X", '"_X', { silent = true })
keymap("", "s", '"_s', { silent = true })
keymap("", "S", '"_S', { silent = true })
keymap("", "c", '"_c', { silent = true })
keymap("", "C", '"_C', { silent = true })
keymap("n", "dd", '"_dd', { silent = true })
keymap("n", "D", '"_D', { silent = true })
keymap("n", "<C-d>", "dd", { silent = true })
keymap("x", "d", '"_d', { silent = true })
keymap("x", "D", '"_D', { silent = true })
keymap("x", "<C-d>", "d", { silent = true })
keymap("v", "p", '"_dP', { silent = true })

-- buffer
keymap("", "<Leader>w", ":w<CR>", { silent = true })
keymap("n", "<Leader>[", "<Cmd>BufferPrevious<CR>", { silent = true })
keymap("n", "<Leader>]", "<Cmd>BufferNext<CR>", { silent = true })
keymap("n", "<Leader>d", "<Cmd>BufferClose<CR>", { silent = true })
keymap("n", "<Leader>to", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", { silent = true })
keymap("n", "<Leader>pp", "<Cmd>BufferPick<CR>", { silent = true })
keymap("n", "<Leader>pd", "<Cmd>BufferPickDelete<CR>", { silent = true })

-- window
keymap("n", "<Leader>gs", ":split<CR>", { silent = true })
keymap("n", "<Leader>gv", ":vsplit<CR>", { silent = true })
keymap("n", "<Leader>gh", "<C-w>h", { silent = true })
keymap("n", "<Leader>gj", "<C-w>j", { silent = true })
keymap("n", "<Leader>gk", "<C-w>k", { silent = true })
keymap("n", "<Leader>gl", "<C-w>l", { silent = true })
keymap("n", "<Leader>gw", "<C-w>w", { silent = true })
keymap("n", "<Leader>gW", "<C-w>W", { silent = true })
keymap("n", "<Leader>gd", "<C-w>c", { silent = true })
keymap("n", "<Leader>gto", "<C-w>o", { silent = true })

-- filer
keymap("n", "<Leader>e", function()
    MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, { silent = true })

-- appearance
keymap("n", "<Esc><Esc>", ":nohlsearch<CR>", { silent = true })

-- search
keymap("n", "*", "*N", { silent = true })

-- register
keymap("n", "<Leader>yj", "<Cmd>JoinRegister<CR>", { silent = true })
