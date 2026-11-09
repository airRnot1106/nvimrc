local M = {}

local latest = { seq = -1 }

--- @param seq integer the request; a newer one replaces it
function M.request(seq)
    local client = require("copilot.client").get()
    if client == nil then
        latest = { seq = seq, texts = {} }
        return
    end
    latest = { seq = seq }
    local params = require("copilot.util").get_doc_params()
    require("copilot.api").get_completions(client, params, function(err, response)
        if latest.seq ~= seq then
            return
        end
        local texts = {}
        if not err and response and response.completions then
            for _, completion in ipairs(response.completions) do
                table.insert(texts, completion.text)
            end
        end
        latest.texts = texts
    end)
end

--- @param seq integer
--- @return string[]|nil texts nil while the answer of the request is pending
function M.poll(seq)
    if latest.seq ~= seq then
        return {}
    end
    return latest.texts
end

--- @param word string
--- @param lines string[]
function M.accept(word, lines)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local start = col - #word
    if start < 0 or vim.api.nvim_get_current_line():sub(start + 1, col) ~= word then
        return
    end
    vim.api.nvim_buf_set_text(0, row - 1, start, row - 1, col, lines)
    local last = #lines[#lines]
    if #lines == 1 then
        last = last + start
    end
    vim.api.nvim_win_set_cursor(0, { row + #lines - 1, last })
end

return M
