-- Tests of lua/goda_cmp_lsp.lua against Neovim's LSP client with in-process
-- fake servers. Run with `nvim -l`, from anywhere.
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(script, ":p:h:h:h:h:h:h")
package.path = root .. "/lua/?.lua;" .. package.path
local lsp = require "goda_cmp_lsp"

local runtime = vim.fn.tempname()
vim.fn.mkdir(runtime .. "/autoload", "p")
vim.fn.writefile({
    "function! goda_cmp#skip_next_complete() abort",
    "  let g:skipped += 1",
    "endfunction",
}, runtime .. "/autoload/goda_cmp.vim")
vim.opt.runtimepath:prepend(runtime)

-- Insert mode allows the cursor after the last character, and the test stays in normal mode.
vim.o.virtualedit = "onemore"

local failures = 0

local function test(name, fn)
    vim.cmd "enew!"
    vim.g.skipped = 0
    local ok, err = xpcall(fn, debug.traceback)
    for _, client in ipairs(vim.lsp.get_clients()) do
        client:stop(true)
    end
    vim.wait(1000, function()
        return #vim.lsp.get_clients() == 0
    end, 5)
    if ok then
        print("ok    " .. name)
    else
        failures = failures + 1
        print("FAIL  " .. name .. "\n" .. err)
    end
end

local function eq(got, want)
    if not vim.deep_equal(got, want) then
        error(("got %s, want %s"):format(vim.inspect(got), vim.inspect(want)), 2)
    end
end

---Starts a fake server on the current buffer. handlers answer requests by method: they get the
---params and a reply function, and an answer may wait for the test.
---@return { client: vim.lsp.Client, requests: table[], notifications: table[] }
local function server(opts)
    local requests, notifications = {}, {}
    local capabilities = vim.tbl_extend("force", {
        positionEncoding = opts.encoding or "utf-16",
        completionProvider = { triggerCharacters = { "." }, resolveProvider = true },
        executeCommandProvider = { commands = { "accepted" } },
        textDocumentSync = 1,
    }, opts.capabilities or {})
    local handlers = opts.handlers or {}
    local id = vim.lsp.start({
        name = opts.name or "fake",
        cmd = function(dispatchers)
            local closing, last_id = false, 0
            return {
                request = function(method, params, callback, on_reply)
                    last_id = last_id + 1
                    local request_id = last_id
                    local function reply(err, result)
                        callback(err, result, request_id)
                        if on_reply then
                            on_reply(request_id)
                        end
                    end
                    if method == "initialize" then
                        reply(nil, { capabilities = capabilities })
                    elseif method == "shutdown" then
                        reply(nil, nil)
                    else
                        requests[#requests + 1] = { method = method, params = params, id = request_id }
                        local handler = handlers[method]
                        if handler then
                            handler(params, reply)
                        end
                    end
                    return true, request_id
                end,
                notify = function(method, params)
                    notifications[#notifications + 1] = { method = method, params = params }
                    if method == "exit" then
                        dispatchers.on_exit(0, 15)
                    end
                    return true
                end,
                is_closing = function()
                    return closing
                end,
                terminate = function()
                    closing = true
                    dispatchers.on_exit(0, 15)
                end,
            }
        end,
    }, { attach = true, reuse_client = false })
    vim.wait(1000, function()
        return vim.lsp.get_client_by_id(id).initialized
    end, 5)
    return { client = vim.lsp.get_client_by_id(id), requests = requests, notifications = notifications }
end

local function answering(items)
    return {
        ["textDocument/completion"] = function(_, reply)
            reply(nil, items)
        end,
    }
end

local function args(input, incomplete)
    return {
        bufnr = vim.api.nvim_get_current_buf(),
        tick = vim.api.nvim_buf_get_changedtick(0),
        lnum = vim.fn.line ".",
        input = input,
        incomplete = incomplete or false,
    }
end

---Polls until the request is done, as Go does, and returns the results.
local function collect(id)
    local results = {}
    while true do
        local text = lsp.poll(id)
        if text ~= "" then
            local answer = vim.json.decode(text)
            vim.list_extend(results, answer.results or {})
            if answer.done then
                return results, answer
            end
        end
        vim.wait(5)
    end
end

local function pending_count()
    local index = 1
    while true do
        local name, value = debug.getupvalue(lsp.start, index)
        if name == "pending" then
            return vim.tbl_count(value)
        end
        assert(name, "start has no pending table")
        index = index + 1
    end
end

test("a buffer without clients has nothing to wait for", function()
    eq(lsp.start(args "fo"), 0)
end)

test("a request made after the text changed asks no server and reports itself stale", function()
    local s = server { handlers = answering {} }
    local a = args "fo"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local _, answer = collect(lsp.start(a))
    eq(answer.stale, true)
    eq(#s.requests, 0)
end)

test("each client gets the position in its own encoding", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "", "日本語😀.fo" })
    vim.api.nvim_win_set_cursor(0, { 2, 16 })
    local wide = server { name = "wide", encoding = "utf-16", handlers = answering {} }
    local narrow = server { name = "narrow", encoding = "utf-8", handlers = answering {} }
    local a = args "日本語😀.fo"
    collect(lsp.start(a))
    eq(wide.requests[1].params.position, { line = 1, character = 8 })
    eq(narrow.requests[1].params.position, { line = 1, character = 16 })
    eq(wide.requests[1].params.textDocument.uri, vim.uri_from_bufnr(0))
end)

test("the request names the trigger character the input ends with", function()
    local s = server { handlers = answering {} }
    collect(lsp.start(args "string."))
    eq(s.requests[1].params.context, { triggerKind = 2, triggerCharacter = "." })
end)

test("a word is an invoked request, or an incomplete one after an incomplete list", function()
    local s = server { handlers = answering {} }
    collect(lsp.start(args "fo"))
    collect(lsp.start(args("foo", true)))
    eq(s.requests[1].params.context, { triggerKind = 1 })
    eq(s.requests[2].params.context, { triggerKind = 3 })
end)

test("clients that do not complete are not asked", function()
    local s = server { capabilities = { completionProvider = false }, handlers = answering {} }
    eq(lsp.start(args "fo"), 0)
    eq(#s.requests, 0)
end)

test("each client's answer keeps its encoding, its client and its defaults", function()
    local list = {
        isIncomplete = true,
        itemDefaults = {
            editRange = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 2 } },
            data = vim.empty_dict(),
        },
        items = { { label = "foo", tags = {} } },
    }
    local a = server { name = "a", encoding = "utf-8", handlers = answering(list) }
    local b = server {
        name = "b",
        encoding = "utf-16",
        capabilities = { completionProvider = { resolveProvider = false } },
        handlers = answering { { label = "bar" } },
    }
    local results = collect(lsp.start(args "fo"))
    table.sort(results, function(x, y)
        return x.clientId < y.clientId
    end)
    eq(#results, 2)
    eq(results[1].clientId, a.client.id)
    eq(results[1].offsetEncoding, "utf-8")
    eq(results[1].resolvable, true)
    eq(results[1].result.isIncomplete, true)
    eq(results[1].result.items[1].label, "foo")
    eq(results[2].clientId, b.client.id)
    eq(results[2].offsetEncoding, "utf-16")
    eq(results[2].resolvable, false)
    eq(results[2].result[1].label, "bar")
end)

test("an empty object of an answer stays an object on its way to Go", function()
    server { handlers = answering { { label = "foo", data = vim.empty_dict(), tags = {} } } }
    local id = lsp.start(args "fo")
    local text
    repeat
        text = lsp.poll(id)
    until text ~= ""
    assert(text:find('"data":{}', 1, true), text)
    assert(text:find('"tags":[]', 1, true), text)
end)

test("the answer of a fast client arrives while a slow one still works", function()
    local release
    server { name = "fast", handlers = answering { { label = "fast" } } }
    server {
        name = "slow",
        handlers = {
            ["textDocument/completion"] = function(_, reply)
                release = function()
                    reply(nil, { { label = "slow" } })
                end
            end,
        },
    }
    local id = lsp.start(args "fo")
    local first = vim.json.decode(lsp.poll(id))
    eq(first.done, false)
    eq(first.results[1].result[1].label, "fast")
    eq(lsp.poll(id), "")
    release()
    local last = vim.json.decode(lsp.poll(id))
    eq(last.done, true)
    eq(last.results[1].result[1].label, "slow")
end)

test("an answer with an error is handed over as an error", function()
    server {
        handlers = {
            ["textDocument/completion"] = function(_, reply)
                reply({ code = -32603, message = "boom" }, nil)
            end,
        },
    }
    local results = collect(lsp.start(args "fo"))
    eq(results[1].error, "boom")
end)

test("cancel tells the unanswered servers and forgets the request", function()
    local s = server { handlers = {} }
    local id = lsp.start(args "fo")
    eq(pending_count(), 1)
    lsp.cancel(id)
    eq(pending_count(), 0)
    local cancels = vim.tbl_filter(function(n)
        return n.method == "$/cancelRequest"
    end, s.notifications)
    eq(cancels[1].params, { id = s.requests[1].id })
    lsp.cancel(id)
    eq(pending_count(), 0)
end)

test("an answer after cancel does not bring the request back", function()
    local late
    server {
        handlers = {
            ["textDocument/completion"] = function(_, reply)
                late = reply
            end,
        },
    }
    lsp.cancel(lsp.start(args "fo"))
    late(nil, { { label = "late" } })
    eq(pending_count(), 0)
end)

test("a request whose text changed cancels itself and reports it", function()
    local s = server { handlers = {} }
    local id = lsp.start(args "fo")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local _, answer = collect(id)
    eq(answer.stale, true)
    eq(pending_count(), 0)
    assert(vim.iter(s.notifications):any(function(n)
        return n.method == "$/cancelRequest"
    end))
end)

test("a request of a deleted buffer ends as stale", function()
    server { handlers = {} }
    local id = lsp.start(args "fo")
    vim.cmd "enew!"
    vim.cmd "bwipeout! #"
    local _, answer = collect(id)
    eq(answer.stale, true)
    eq(pending_count(), 0)
end)

test("a request nobody polls is dropped by the next request after the text changed", function()
    server { handlers = {} }
    lsp.start(args "fo")
    eq(pending_count(), 1)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    lsp.cancel(lsp.start(args "changed"))
    eq(pending_count(), 0)
end)

test("answered, cancelled and stale requests leave nothing behind", function()
    server { handlers = answering { { label = "foo" } } }
    for _ = 1, 200 do
        collect(lsp.start(args "fo"))
        lsp.cancel(lsp.start(args "fo"))
    end
    eq(pending_count(), 0)
end)

local function resolve_args(client_id, item)
    return { clientId = client_id, bufnr = vim.api.nvim_get_current_buf(), item = vim.json.encode(item) }
end

test("resolve hands the item to its client and returns the answer", function()
    local s = server {
        handlers = {
            ["completionItem/resolve"] = function(item, reply)
                reply(nil, vim.tbl_extend("force", item, { documentation = "doc" }))
            end,
        },
    }
    local results = collect(lsp.resolve(resolve_args(s.client.id, { label = "foo", data = { id = 1 } })))
    eq(s.requests[1].params, { label = "foo", data = { id = 1 } })
    eq(results[1].result, { label = "foo", data = { id = 1 }, documentation = "doc" })
end)

test("resolve of a client that exited has nothing to wait for", function()
    eq(lsp.resolve { clientId = 999, bufnr = 1, item = "{}" }, 0)
end)

test("a failed resolve hands over the server's message", function()
    local s = server {
        handlers = {
            ["completionItem/resolve"] = function(_, reply)
                reply({ code = -32603, message = "boom" }, nil)
            end,
        },
    }
    local results = collect(lsp.resolve(resolve_args(s.client.id, { label = "foo" })))
    eq(results[1].error, "boom")
end)

test("a resolve ends as stale when the selection changes the text", function()
    local s = server { handlers = {} }
    local id = lsp.resolve(resolve_args(s.client.id, { label = "foo" }))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
    local _, answer = collect(id)
    eq(answer.stale, true)
    eq(pending_count(), 0)
end)

test("poll runs the callbacks Neovim has scheduled", function()
    local arrived = false
    vim.schedule(function()
        arrived = true
    end)
    lsp.poll(0)
    eq(arrived, true)
end)

---Fills the buffer. "|" in lines marks the cursor.
local function buffer(lines)
    local row, col
    local text = {}
    for i, line in ipairs(lines) do
        local at = line:find("|", 1, true)
        if at then
            row, col = i, at - 1
            line = line:sub(1, at - 1) .. line:sub(at + 1)
        end
        text[i] = line
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
    vim.api.nvim_win_set_cursor(0, { row, col })
    return row
end

---The buffer with "|" at the cursor.
local function shown()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    lines[row] = lines[row]:sub(1, col) .. "|" .. lines[row]:sub(col + 1)
    return lines
end

---The popup replaced `typed`, the word at the request, with `word`.
local function confirm(c)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before_word = vim.api.nvim_get_current_line():sub(1, col - #c.word)
    lsp.confirm(vim.json.encode(vim.tbl_extend("keep", c, {
        bufnr = vim.api.nvim_get_current_buf(),
        lnum = vim.fn.line ".",
        input = before_word .. (c.typed or c.word),
        tail = 0,
        snippet = false,
        clientId = 0,
        offsetEncoding = "utf-16",
    })))
end

test("an item whose word is its text leaves the buffer alone", function()
    buffer { "foo|" }
    local tick = vim.api.nvim_buf_get_changedtick(0)
    confirm { word = "foo", start = 0, text = "foo" }
    eq(vim.api.nvim_buf_get_changedtick(0), tick)
    eq(vim.g.skipped, 0)
end)

test("an item is left alone once more was typed after it", function()
    buffer { "foox|" }
    confirm { word = "foo", start = 0, text = "foo()" }
    eq(shown(), { "foox|" })
    eq(vim.g.skipped, 0)
end)

test("the same word typed again after the accepted one is left alone", function()
    buffer { "foo foo|" }
    confirm { input = "fo", word = "foo", start = 0, text = "foo()" }
    eq(shown(), { "foo foo|" })
end)

test("an item of another line is left alone", function()
    local row = buffer { "foo", "bar|" }
    confirm { lnum = row - 1, word = "bar", start = 0, text = "bar()" }
    eq(shown(), { "foo", "bar|" })
end)

test("the text of the item replaces the word and the next completion is skipped", function()
    buffer { "foo|" }
    confirm { word = "foo", start = 0, text = "foo()" }
    eq(shown(), { "foo()|" })
    eq(vim.g.skipped, 1)
end)

test("the edit of the item replaces the word from its own start", function()
    buffer { "obj->prop|foo" }
    confirm { word = "->prop", typed = ".p", start = 3, text = "->prop()" }
    eq(shown(), { "obj->prop()|foo" })
end)

test("an edit past the cursor replaces that text too", function()
    buffer { "fmt.Println|int" }
    confirm { word = "Println", typed = "Pr", start = 4, tail = 3, text = "Println" }
    eq(shown(), { "fmt.Println|" })
end)

test("an indentation fixing edit removes the indentation", function()
    buffer { "<div>", "  </div|foo>" }
    confirm { word = "</div", typed = "</d", start = 0, text = "</div" }
    eq(shown(), { "<div>", "</div|foo>" })
end)

test("a multi-line text leaves the cursor at its end", function()
    buffer { "fo|o" }
    confirm { word = "fo", start = 0, text = "a\nb" }
    eq(shown(), { "a", "b|o" })
end)

test("an import above the cursor keeps the cursor on its text", function()
    buffer { "const a = 1;", "join|;" }
    confirm {
        word = "join",
        start = 0,
        text = "join",
        additionalTextEdits = {
            {
                newText = 'import { join } from "node:path";\n',
                range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
            },
        },
    }
    eq(shown(), { 'import { join } from "node:path";', "const a = 1;", "join|;" })
end)

test("an import at the very place of the word goes before the word", function()
    buffer { "join|" }
    confirm {
        word = "join",
        start = 0,
        text = "join",
        additionalTextEdits = {
            {
                newText = 'import { join } from "node:path";\n\n',
                range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
            },
        },
    }
    eq(shown(), { 'import { join } from "node:path";', "", "join|" })
end)

test("an additional edit right of the word uses the columns of the request", function()
    buffer { "foo(bar|, qux)" }
    confirm {
        word = "bar",
        typed = "ba",
        start = 4,
        text = "bar",
        additionalTextEdits = {
            {
                newText = "await ",
                range = { start = { line = 0, character = 8 }, ["end"] = { line = 0, character = 8 } },
            },
        },
    }
    eq(shown(), { "foo(bar|, await qux)" })
end)

test("additional edits use the encoding of the client", function()
    buffer { "😀x", "fo|" }
    confirm {
        word = "fo",
        start = 0,
        text = "foo",
        offsetEncoding = "utf-16",
        additionalTextEdits = {
            { newText = "y", range = { start = { line = 0, character = 2 }, ["end"] = { line = 0, character = 3 } } },
        },
    }
    eq(shown(), { "😀y", "foo|" })
    buffer { "😀x", "fo|" }
    confirm {
        word = "fo",
        start = 0,
        text = "foo",
        offsetEncoding = "utf-8",
        additionalTextEdits = {
            { newText = "y", range = { start = { line = 0, character = 4 }, ["end"] = { line = 0, character = 5 } } },
        },
    }
    eq(shown(), { "😀y", "foo|" })
end)

test("additional edits that take the line of the cursor keep the insertion in place", function()
    buffer { "fn main() {", '  let s = ""', "    .dbg|foo", "}" }
    confirm {
        word = "dbg",
        typed = "d",
        start = 5,
        text = 'dbg!("")',
        additionalTextEdits = {
            { newText = "", range = { start = { line = 1, character = 10 }, ["end"] = { line = 2, character = 5 } } },
        },
    }
    eq(shown(), { "fn main() {", '  let s = dbg!("")|foo', "}" })
end)

test("a snippet expands where the word was", function()
    buffer { "local x = fun|" }
    confirm { word = "fun", start = 10, text = "function ${1:name}()\n\t$0\nend", snippet = true }
    eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "local x = function name()", "\t", "end" })
    eq(vim.snippet.active(), true)
    vim.snippet.stop()
end)

test("a snippet with an import above it still expands in place", function()
    buffer { "a", "fo|" }
    confirm {
        word = "fo",
        start = 0,
        text = "foo($1)",
        snippet = true,
        additionalTextEdits = {
            {
                newText = "import\n",
                range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
            },
        },
    }
    eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "import", "a", "foo()" })
    vim.snippet.stop()
end)

test("a snippet that cannot expand leaves the word", function()
    buffer { "fo|" }
    confirm { word = "fo", start = 0, text = "${1:a} ${1:b}", snippet = true }
    eq(shown(), { "fo|" })
    eq(vim.g.skipped, 1)
end)

test("the command of the item reaches the server", function()
    local s = server { handlers = { ["workspace/executeCommand"] = function() end } }
    buffer { "foo|" }
    confirm {
        clientId = s.client.id,
        word = "foo",
        start = 0,
        text = "foo",
        command = { title = "t", command = "accepted" },
    }
    eq(s.requests[1].method, "workspace/executeCommand")
    eq(s.requests[1].params.command, "accepted")
end)

if failures > 0 then
    print(failures .. " failed")
    os.exit(1)
end
