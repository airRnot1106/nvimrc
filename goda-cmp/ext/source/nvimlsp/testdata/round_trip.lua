-- One completion through the whole chain: the engine and the source in the Go
-- test binary, lua/goda_cmp_lsp.lua and Neovim's LSP client with fake servers.
-- nvimlsp_test.go runs it with `nvim -l`.
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(script, ":p:h:h:h:h:h:h")
package.path = root .. "/lua/?.lua;" .. package.path

local runtime = vim.fn.tempname()
vim.fn.mkdir(runtime .. "/autoload/goda_cmp_testui", "p")
vim.fn.writefile({
    "function! goda_cmp_testui#test#show(r) abort",
    "  call add(g:shown, a:r)",
    "endfunction",
    "function! goda_cmp_testui#test#hide() abort",
    "endfunction",
}, runtime .. "/autoload/goda_cmp_testui/test.vim")
for _, dir in ipairs { runtime, os.getenv "GODA_RTP", os.getenv "GODA_CMP_RTP" } do
    vim.opt.runtimepath:prepend(dir)
end
vim.g.shown = {}
-- Insert mode allows the cursor after the last character, and the test stays in normal mode.
vim.o.virtualedit = "onemore"

local function eq(got, want)
    if not vim.deep_equal(got, want) then
        error(("got %s, want %s"):format(vim.inspect(got), vim.inspect(want)), 2)
    end
end

local function wait_for(what, predicate)
    if not vim.wait(5000, predicate, 5) then
        error("timed out waiting for " .. what .. "\n" .. table.concat(vim.fn["goda#log"](), "\n"), 2)
    end
end

local function server(encoding, handlers)
    local id = vim.lsp.start({
        name = encoding,
        cmd = function(dispatchers)
            local last_id = 0
            return {
                request = function(method, params, callback, on_reply)
                    last_id = last_id + 1
                    local request_id = last_id
                    local function reply(result)
                        callback(nil, result, request_id)
                        if on_reply then
                            on_reply(request_id)
                        end
                    end
                    if method == "initialize" then
                        reply {
                            capabilities = {
                                positionEncoding = encoding,
                                completionProvider = { triggerCharacters = { "." }, resolveProvider = true },
                                textDocumentSync = 1,
                            },
                        }
                    elseif method == "textDocument/completion" then
                        -- Late enough for the request below to arrive during the gather.
                        vim.defer_fn(function()
                            reply(handlers[method](params))
                        end, 100)
                    elseif handlers[method] then
                        reply(handlers[method](params))
                    else
                        reply(nil)
                    end
                    return true, request_id
                end,
                notify = function(method)
                    if method == "exit" then
                        dispatchers.on_exit(0, 15)
                    end
                    return true
                end,
                is_closing = function()
                    return false
                end,
                terminate = function() end,
            }
        end,
    }, { attach = true, reuse_client = false })
    wait_for("the server", function()
        return vim.lsp.get_client_by_id(id).initialized
    end)
end

local function range(line, from, to)
    return { start = { line = line, character = from }, ["end"] = { line = line, character = to } }
end

-- "😀" is 4 bytes and 2 UTF-16 units: both servers must end up at the same column.
local line = "😀.jo"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "const a = 1;", line })
vim.api.nvim_win_set_cursor(0, { 2, #line })

server("utf-16", {
    ["textDocument/completion"] = function(params)
        eq(params.position, { line = 1, character = 5 })
        return {
            isIncomplete = false,
            itemDefaults = { editRange = range(1, 3, 5), data = { server = "wide" } },
            items = { { label = "join", kind = 3, sortText = "1" } },
        }
    end,
    ["completionItem/resolve"] = function(item)
        eq(item.data, { server = "wide" })
        return vim.tbl_extend("force", item, {
            documentation = "joins",
            additionalTextEdits = { { newText = "import join;\n", range = range(0, 0, 0) } },
        })
    end,
})
server("utf-8", {
    ["textDocument/completion"] = function(params)
        eq(params.position, { line = 1, character = 7 })
        return { { label = "jog", kind = 2, sortText = "2", textEdit = { newText = "jog", range = range(1, 5, 7) } } }
    end,
})

local tick = vim.api.nvim_buf_get_changedtick(0)
vim.fn["goda#start"](os.getenv "NVIMLSP_BIN")
vim.fn["goda#notify"]("cmp", "complete", {
    seq = 1,
    tick = tick,
    bufnr = vim.api.nvim_get_current_buf(),
    lnum = 2,
    col = #line + 1,
    input = line,
    nextinput = "",
    filetype = "typescript",
    mode = "i",
    cmdtype = "",
    manual = false,
    event = "TextChangedI",
    patches = vim.empty_dict(),
})
-- The request waits for the gather while Neovim waits for the request.
local t0 = vim.uv.hrtime()
vim.fn["goda#request"]("cmp", "sources")
local waited = (vim.uv.hrtime() - t0) / 1e6
assert(waited < 1000, ("the gather kept Neovim waiting for %d ms"):format(waited))

wait_for("both clients in the popup", function()
    local shown = vim.g.shown
    return #shown > 0 and #shown[#shown].items == 2
end)
local shown = vim.g.shown[#vim.g.shown]
eq(shown.col, 6)
local words = vim.tbl_map(function(it)
    return it.word
end, shown.items)
table.sort(words)
eq(words, { "jog", "join" })

local join = vim.iter(shown.items):find(function(it)
    return it.word == "join"
end)
eq(join.kind, "Function")
eq(join.menu, "[LSP]")

local resolved = vim.fn["goda#request"]("cmp", "resolve", join.user_data)
eq(resolved.info, "joins")

local preview = vim.fn["goda#request"]("cmp", "preview", join.user_data)
eq(preview, { kind = "markdown", contents = { "joins" } })

vim.api.nvim_buf_set_lines(0, 1, 2, false, { "😀.join" })
vim.api.nvim_win_set_cursor(0, { 2, #"😀.join" })
vim.fn["goda#notify"]("cmp", "done", join.user_data)
wait_for("the import", function()
    return vim.api.nvim_buf_line_count(0) == 3
end)
eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "import join;", "const a = 1;", "😀.join" })
eq(vim.api.nvim_win_get_cursor(0), { 3, #"😀.join" })

local index = 1
while true do
    local name, value = debug.getupvalue(require("goda_cmp_lsp").start, index)
    assert(name, "start has no pending table")
    if name == "pending" then
        eq(vim.tbl_count(value), 0)
        break
    end
    index = index + 1
end
