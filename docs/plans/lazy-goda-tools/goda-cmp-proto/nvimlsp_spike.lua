local M = {}
local pending, seq = {}, 0

local function to_item(it, encoding)
    local snippet = it.insertTextFormat == 2
    local text = (it.textEdit and it.textEdit.newText) or it.insertText or it.label
    return {
        word = snippet and it.label:match "^[%w_]+" or text,
        abbr = it.label,
        kind = vim.lsp.protocol.CompletionItemKind[it.kind or 0] or "",
        filterText = it.filterText or it.label,
        sortText = it.sortText or it.label,
        snippet = snippet and text or "",
        edits = it.additionalTextEdits or {},
        encoding = encoding,
    }
end

function M.start(bufnr)
    seq = seq + 1
    local id = seq
    pending[id] = { done = false }
    if #vim.lsp.get_clients { bufnr = bufnr, method = "textDocument/completion" } == 0 then
        pending[id] = { done = true, items = {} }
        return id
    end
    vim.lsp.buf_request_all(bufnr, "textDocument/completion", function(client)
        return vim.lsp.util.make_position_params(0, client.offset_encoding)
    end, function(results)
        local items, incomplete = {}, false
        for cid, r in pairs(results) do
            local res = r.result or {}
            local enc = vim.lsp.get_client_by_id(cid).offset_encoding
            incomplete = incomplete or res.isIncomplete == true
            for _, it in ipairs(res.items or res) do
                items[#items + 1] = to_item(it, enc)
            end
        end
        pending[id] = { done = true, items = items, incomplete = incomplete }
    end)
    return id
end

function M.poll(id)
    local p = pending[id]
    if p and p.done then
        pending[id] = nil
    end
    return p
end

function M.done(a)
    if #a.edits > 0 then
        vim.lsp.util.apply_text_edits(a.edits, 0, a.encoding)
    end
    if a.snippet ~= "" then
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_text(0, row - 1, col - #a.word, row - 1, col, {})
        vim.api.nvim_win_set_cursor(0, { row, col - #a.word })
        vim.snippet.expand(a.snippet)
    end
end

return M
