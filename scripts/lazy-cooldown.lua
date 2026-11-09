-- Usage: nvim -l scripts/lazy-cooldown.lua [--check] [--lock <file>] [--root <dir>]
-- Moves each plugin in lazy-lock.json to the newest commit that is at least MIN_AGE_DAYS old.
-- Run `:Lazy restore` afterwards. `--check` only reports commits that are too new.
local MIN_AGE_DAYS = 7
-- goda.vim plugins and their binaries must stay on the same protocol version
local EXEMPT_REPOS = { "[/:]airRnot1106/", "[/:]Shougo/goda" }

local function option(flag, default)
    for i, value in ipairs(vim.v.argv) do
        if value == flag then
            return vim.v.argv[i + 1]
        end
    end
    return default
end

local check_only = vim.tbl_contains(vim.v.argv, "--check")
local lock_path = option("--lock", vim.fn.stdpath "config" .. "/lazy-lock.json")
local root = option("--root", vim.fn.stdpath "data" .. "/lazy")
local cutoff = os.time() - MIN_AGE_DAYS * 86400

local function git(dir, ...)
    local result = vim.system({ "git", "-C", dir, ... }, { text = true }):wait()
    return result.code == 0 and vim.trim(result.stdout) or nil
end

local function is_exempt(dir)
    local url = git(dir, "remote", "get-url", "origin") or ""
    for _, pattern in ipairs(EXEMPT_REPOS) do
        if url:find(pattern) then
            return true
        end
    end
    return false
end

local function newest_allowed(dir, branch, exempt)
    if exempt then
        return git(dir, "rev-parse", "origin/" .. branch)
    end
    local commit = git(dir, "log", "-1", "--format=%H", "--before=" .. cutoff, "origin/" .. branch)
    return commit ~= "" and commit or nil
end

local function write_lock(lock, names)
    local lines = { "{" }
    for i, name in ipairs(names) do
        local entry = lock[name]
        lines[#lines + 1] = string.format(
            '  %s: { "branch": %s, "commit": %s }%s',
            vim.json.encode(name),
            vim.json.encode(entry.branch),
            vim.json.encode(entry.commit),
            i < #names and "," or ""
        )
    end
    lines[#lines + 1] = "}"
    vim.fn.writefile(lines, lock_path)
end

local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
local names = vim.tbl_keys(lock)
table.sort(names)

local too_new = {}
for _, name in ipairs(names) do
    local entry = lock[name]
    local dir = root .. "/" .. name
    if vim.fn.isdirectory(dir) == 1 then
        local exempt = is_exempt(dir)
        if check_only then
            local time = tonumber(git(dir, "show", "-s", "--format=%ct", entry.commit))
            if not exempt and time and time > cutoff then
                too_new[#too_new + 1] = name
            end
        else
            git(dir, "fetch", "--quiet", "origin")
            local target = newest_allowed(dir, entry.branch, exempt)
            if target and git(dir, "merge-base", "--is-ancestor", entry.commit, target) then
                entry.commit = target
            end
        end
    end
end

if check_only then
    if #too_new > 0 then
        print("commits newer than " .. MIN_AGE_DAYS .. " days: " .. table.concat(too_new, ", "))
        os.exit(1)
    end
else
    write_lock(lock, names)
end
