-- The Neovim side of the goda-cmp source "nvimlsp" (goda-cmp/ext/source/nvimlsp).
-- It talks to the LSP clients attached to a buffer and starts no language server.
-- Answers cross to Go as JSON text: Go keeps the items as the server sent them, for
-- completionItem/resolve.
local M = {}

local json_options = { luanil = { object = true } }

---@class goda_cmp_lsp.Pending
---@field bufnr integer
---@field tick integer b:changedtick of the request
---@field requests table<integer, integer> request id by client id, of the unanswered clients
---@field results table[] answers Go has not fetched yet

---@type table<integer, goda_cmp_lsp.Pending>
local pending = {}
local last_id = 0

---@param p goda_cmp_lsp.Pending
---@return integer id
local function register(p)
    last_id = last_id + 1
    pending[last_id] = p
    return last_id
end

---@param client vim.lsp.Client
---@param input string
---@param incomplete boolean
---@return lsp.CompletionContext
local function completion_context(client, input, incomplete)
    local kind = vim.lsp.protocol.CompletionTriggerKind
    local provider = client.server_capabilities.completionProvider or {}
    for _, char in ipairs(provider.triggerCharacters or {}) do
        if vim.endswith(input, char) then
            return { triggerKind = kind.TriggerCharacter, triggerCharacter = char }
        end
    end
    return { triggerKind = incomplete and kind.TriggerForIncompleteCompletions or kind.Invoked }
end

---@param p goda_cmp_lsp.Pending
---@param client vim.lsp.Client
---@param method string
---@param params table
local function ask(p, client, method, params)
    local answered = false
    local ok, request_id = client:request(method, params, function(err, result)
        answered = true
        p.requests[client.id] = nil
        p.results[#p.results + 1] = {
            clientId = client.id,
            offsetEncoding = client.offset_encoding,
            resolvable = vim.tbl_get(client.server_capabilities, "completionProvider", "resolveProvider") == true,
            result = result,
            error = err and err.message,
        }
    end, p.bufnr)
    if ok and not answered then
        p.requests[client.id] = request_id
    end
end

---@param p goda_cmp_lsp.Pending
---@return boolean
local function is_stale(p)
    return not vim.api.nvim_buf_is_valid(p.bufnr) or vim.api.nvim_buf_get_changedtick(p.bufnr) ~= p.tick
end

---Cancels a request. It is safe for a request that already ended.
---@param id integer
function M.cancel(id)
    local p = pending[id]
    pending[id] = nil
    if not p then
        return
    end
    for client_id, request_id in pairs(p.requests) do
        local client = vim.lsp.get_client_by_id(client_id)
        if client then
            client:cancel_request(request_id)
        end
    end
end

---Asks every client attached to the buffer for completion. A request of older text asks nobody,
---and poll() reports it as stale.
---@param args { bufnr: integer, tick: integer, lnum: integer, input: string, incomplete: boolean }
---@return integer id the id for poll() and cancel(), 0 when there is nothing to wait for
function M.start(args)
    -- Go has no id to cancel when it gave up during this call.
    for id, p in pairs(pending) do
        if is_stale(p) then
            M.cancel(id)
        end
    end
    local clients = vim.lsp.get_clients { bufnr = args.bufnr, method = "textDocument/completion" }
    if #clients == 0 then
        return 0
    end
    local p = { bufnr = args.bufnr, tick = args.tick, requests = {}, results = {} }
    if not is_stale(p) then
        local uri = vim.uri.from_buf(args.bufnr)
        for _, client in ipairs(clients) do
            ask(p, client, "textDocument/completion", {
                textDocument = { uri = uri },
                position = {
                    line = args.lnum - 1,
                    character = vim.str_utfindex(args.input, client.offset_encoding),
                },
                context = completion_context(client, args.input, args.incomplete),
            })
        end
    end
    return register(p)
end

---Asks a client to resolve an item. A change of the text cancels this, as the user moved on.
---@param args { clientId: integer, bufnr: integer, item: string }
---@return integer id the id for poll() and cancel(), 0 when the client is gone
function M.resolve(args)
    local client = vim.lsp.get_client_by_id(args.clientId)
    if not client then
        return 0
    end
    local p = {
        bufnr = args.bufnr,
        tick = vim.api.nvim_buf_get_changedtick(args.bufnr),
        requests = {},
        results = {},
    }
    ask(p, client, "completionItem/resolve", vim.json.decode(args.item, json_options))
    return register(p)
end

---Hands over what arrived since the last call. A request whose text changed ends here, since
---goda.vim runs cmp.complete notifications one at a time and the newer one cannot cancel it.
---@param id integer
---@return string answer "" while nothing is new, otherwise JSON of { done, stale, results }
function M.poll(id)
    -- Neovim runs no LSP callback while it waits in rpcrequest(), which a goda#request() during a
    -- gather makes it do, and that request waits for the gather.
    vim.wait(0)
    local p = pending[id]
    if not p then
        return vim.json.encode { done = true, stale = true }
    end
    if is_stale(p) then
        M.cancel(id)
        return vim.json.encode { done = true, stale = true }
    end
    local done = next(p.requests) == nil
    if #p.results == 0 and not done then
        return ""
    end
    local results = p.results
    p.results = {}
    if done then
        pending[id] = nil
    end
    return vim.json.encode { done = done, stale = false, results = results }
end

---@param bufnr integer
---@param text string
local function insert_at_cursor(bufnr, text)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.split(text, "\r?\n")
    vim.api.nvim_buf_set_text(bufnr, row - 1, col, row - 1, col, lines)
    local last_col = #lines == 1 and col + #text or #lines[#lines]
    vim.api.nvim_win_set_cursor(0, { row + #lines - 1, last_col })
end

---@class goda_cmp_lsp.Confirmation
---@field bufnr integer
---@field lnum integer
---@field input string the line before the cursor at the request
---@field word string the text the popup inserted before the cursor
---@field start integer byte column of the request's line where the item's edit starts
---@field tail integer bytes after the cursor the item's edit replaces
---@field text string
---@field snippet boolean
---@field clientId integer
---@field offsetEncoding string
---@field additionalTextEdits? lsp.TextEdit[]
---@field command? lsp.Command

---Turns the word the popup inserted into what the server meant to insert.
---@param json string JSON of a goda_cmp_lsp.Confirmation
function M.confirm(json)
    ---@type goda_cmp_lsp.Confirmation
    local c = vim.json.decode(json, json_options)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if vim.api.nvim_get_current_buf() ~= c.bufnr or row ~= c.lnum then
        return
    end
    local line = vim.api.nvim_get_current_line()
    local word_start = col - #c.word
    -- The word is gone when more was typed: pum.vim reports the item on the next key.
    if
        word_start < 0
        or line:sub(word_start + 1, col) ~= c.word
        or line:sub(1, word_start) ~= c.input:sub(1, word_start)
    then
        return
    end
    local edits = c.additionalTextEdits or {}
    local stop = math.min(col + c.tail, #line)
    if line:sub(c.start + 1, stop) == c.text and not c.snippet and #edits == 0 and not c.command then
        return
    end

    vim.cmd "let &undolevels = &undolevels"
    -- The additional edits refer to the line of the request.
    vim.api.nvim_buf_set_text(c.bufnr, row - 1, word_start, row - 1, col, { c.input:sub(word_start + 1) })
    vim.api.nvim_win_set_cursor(0, { row, #c.input })
    vim.lsp.util.apply_text_edits(edits, c.bufnr, c.offsetEncoding, nil, { keep_cursor = true })

    row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local from = col - (#c.input - c.start)
    local to = math.min(col + c.tail, #vim.api.nvim_get_current_line())
    vim.api.nvim_buf_set_text(c.bufnr, row - 1, from, row - 1, to, { "" })
    vim.api.nvim_win_set_cursor(0, { row, from })
    if not c.snippet then
        insert_at_cursor(c.bufnr, c.text)
    elseif not pcall(vim.snippet.expand, c.text) then
        insert_at_cursor(c.bufnr, c.word)
    end

    local client = vim.lsp.get_client_by_id(c.clientId)
    if c.command and client then
        client:exec_cmd(c.command, { bufnr = c.bufnr })
    end
    vim.fn["goda_cmp#skip_next_complete"]()
end

return M
