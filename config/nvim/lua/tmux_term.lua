-- =============================================================================
-- lua/tmux_term.lua — one tmux pane below nvim, following your file
-- =============================================================================
-- A small Lua module that manages a single "terminal" tmux pane per window.
-- The pane is identified by the tmux user-option `@term=1` (set when we create
-- it), so we can always find it again without tracking pane IDs across nvim
-- restarts.
--
-- Public API:
--   M.open()         Open or focus the term pane, cd'd to the current file's
--                    git project root (or file's dir if not in a repo).
--   M.resize(lines)  Resize the term pane to `lines` rows.
--   M.run(text)      Send `text` followed by Enter to the term pane.
--                    Newlines inside `text` run as separate commands.
--
-- Suggested keymaps (set in init.lua):
--   <leader>tt  →  open()
--   <leader>tk  →  resize(25)
--   <leader>tr  →  run(<visual selection>)
-- =============================================================================

local M = {}

-- Make sure we're inside a tmux session before doing anything tmux-ish.
local function ensure_tmux()
    if vim.env.TMUX == nil then
        vim.notify("Not running in a tmux session", vim.log.levels.WARN)
        return false
    end
    return true
end

-- Returns the pane_id of the @term=1 pane in the current tmux window, or nil.
local function find_pane()
    local pane = nil
    local handle = io.popen("tmux list-panes -F '#{pane_id} #{@term}'")
    if handle then
        for line in handle:lines() do
            local id, marker = line:match("(%S+)%s+(%S*)")
            if marker == "1" then
                pane = id
                break
            end
        end
        handle:close()
    end
    return pane
end

-- Returns the git toplevel dir containing `path`, or path's own dir if not in a repo.
local function project_root(path)
    if path == nil or path == "" then
        return vim.fn.getcwd()
    end
    local file_dir = vim.fn.fnamemodify(path, ":p:h")
    local cmd = string.format("git -C %s rev-parse --show-toplevel 2>/dev/null",
                              vim.fn.shellescape(file_dir))
    local root = vim.fn.system(cmd):gsub("\n", "")
    if root ~= "" then return root end
    return file_dir
end

-- Open or focus the term pane, cd'd to the current file's project root.
function M.open()
    if not ensure_tmux() then return end

    local bufname = vim.api.nvim_buf_get_name(0)
    local dir = project_root(bufname)
    local pane = find_pane()

    if pane then
        -- Existing pane: cd it (leading space keeps it out of shell history
        -- when HIST_IGNORE_SPACE is set) and focus it.
        vim.fn.system({ "tmux", "send-keys", "-t", pane,
                        " cd " .. vim.fn.shellescape(dir), "Enter" })
        vim.fn.system({ "tmux", "select-pane", "-t", pane })
    else
        -- No pane yet: split below, 10 lines tall, cd'd to dir. Mark it.
        vim.fn.system({ "tmux", "split-window", "-v", "-l", "10", "-c", dir })
        vim.fn.system({ "tmux", "set-option", "-p", "@term", "1" })
    end
end

-- Resize the term pane to a specific number of rows.
function M.resize(lines)
    if not ensure_tmux() then return end
    local pane = find_pane()
    if not pane then
        vim.notify("No tmux term pane yet — press <leader>tt to open one first",
                   vim.log.levels.INFO)
        return
    end
    vim.fn.system({ "tmux", "resize-pane", "-t", pane, "-y", tostring(lines) })
end

-- Send raw text + Enter to the term pane. Newlines inside `text` act as Enter
-- between commands (each line runs as its own command).
function M.run(text)
    if not ensure_tmux() then return end
    local pane = find_pane()
    if not pane then
        vim.notify("No tmux term pane yet — press <leader>tt to open one first",
                   vim.log.levels.INFO)
        return
    end
    vim.fn.system({ "tmux", "send-keys", "-t", pane, text, "Enter" })
end

return M
