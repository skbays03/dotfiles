-- =============================================================================
-- init.lua — entry point for Shawn's Neovim config
-- =============================================================================
--
-- Load order:
--   1. Leader keys (must be set BEFORE plugins, since plugin keymaps use them)
--   2. Editor options
--   3. Core keymaps (no plugins needed)
--   4. lazy.nvim bootstrap + plugin import from lua/plugins.lua
--
-- All plugin specs live in `lua/plugins.lua`. Edit that file to add/remove
-- plugins; lazy.nvim picks up the changes on next launch (or `:Lazy sync`).
-- =============================================================================



-- =============================================================================
-- 1. Leader keys
-- =============================================================================
-- The leader is a prefix used in custom keybindings (e.g. <leader>ff means
-- press <space> then f then f, since we use space as leader). Setting it
-- BEFORE lazy loads is critical — any plugin keymap defined with <leader>
-- captures whatever the leader is AT DEFINITION TIME.

vim.g.mapleader = " "
vim.g.maplocalleader = " "



-- =============================================================================
-- 2. Options
-- =============================================================================

local opt = vim.opt

-- ---- Line numbers ------------------------------------------------------------
-- Both at once: current line shows absolute, others show relative offsets.
-- Relative numbers are what vim motions like 5dd / 8j actually consume —
-- huge readability win once you're using them.
opt.number = true
opt.relativenumber = true

-- ---- Indentation -------------------------------------------------------------
-- 4-space soft tabs as defaults. Filetype plugins override per-language later
-- (e.g. Lua and JS prefer 2; treesitter/LSP usually handle it).
opt.tabstop = 4         -- visual width of a tab character
opt.shiftwidth = 4      -- spaces inserted by autoindent / >> / <<
opt.expandtab = true    -- pressing <Tab> inserts spaces, not a tab char
opt.smartindent = true  -- guess indent on new lines based on syntax

-- ---- Search ------------------------------------------------------------------
opt.ignorecase = true   -- /Foo matches "foo"
opt.smartcase = true    -- ...unless pattern has uppercase (sift's -S idea)
opt.incsearch = true    -- highlight partial matches as you type
opt.hlsearch = true     -- highlight all matches (clear with <Esc> — see keymaps)

-- ---- UI ----------------------------------------------------------------------
opt.termguicolors = true   -- 24-bit color (modern terminals support this)
opt.signcolumn = "yes"     -- always reserve gutter (prevents text shifting when
                           -- diagnostics/git signs appear)
opt.cursorline = true      -- highlight the line the cursor is on
opt.scrolloff = 8          -- keep 8 lines visible above/below cursor when scrolling
opt.wrap = false           -- no soft-wrapping (toggle with :set wrap if needed)

-- ---- Behavior ----------------------------------------------------------------
opt.mouse = "a"               -- mouse works in all modes (handy for window resize)
opt.clipboard = "unnamedplus" -- y/p use the system clipboard (Cmd-V to paste etc.)
opt.updatetime = 250          -- faster CursorHold trigger (used by LSP highlights)
opt.timeoutlen = 300          -- faster which-key popup (waits 300ms after leader)
opt.undofile = true           -- persistent undo across sessions
opt.swapfile = false          -- no .swp files cluttering directories
opt.splitright = true         -- :vsplit opens to the right (intuitive default)
opt.splitbelow = true         -- :split opens below



-- =============================================================================
-- 3. Core keymaps (built-in vim functionality only — plugin keymaps live with
--    each plugin's spec in lua/plugins.lua)
-- =============================================================================

local map = vim.keymap.set

-- Clear search highlight with <Esc> in normal mode. Almost everyone adds this —
-- hlsearch is great while searching, annoying once you've found the match.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Window navigation with Ctrl + hjkl (instead of Ctrl-w then h/j/k/l).
-- Very common quality-of-life addition.
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Keep cursor centered when scrolling half-pages (Ctrl-d / Ctrl-u).
-- Reduces the visual jolt of large jumps.
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half-page (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half-page (centered)" })

-- Same idea for search jumps (n / N) — center the match on the screen.
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- <leader>s — insert filetype skeleton.
-- Looks for ~/.config/nvim/templates/<filetype>.skel and reads it in at cursor.
-- Drop new template files in that dir for any filetype (python.skel, c.skel, ...).
map("n", "<leader>s", function()
    local ft = vim.bo.filetype
    if ft == "" then
        vim.notify("No filetype detected; can't pick a template.", vim.log.levels.WARN)
        return
    end
    local template = vim.fn.stdpath("config") .. "/templates/" .. ft .. ".skel"
    if vim.fn.filereadable(template) == 0 then
        vim.notify("No template at " .. template, vim.log.levels.WARN)
        return
    end
    -- `:read FILE` inserts after the current line. Use `0read` to insert at top.
    vim.cmd("read " .. template)
end, { desc = "Insert filetype skeleton" })

-- <leader>tt — tmux terminal pane that follows the current file's directory.
-- First press: split a new pane below, cd to current file's dir, focus it.
-- Subsequent presses: cd the same pane to the new file's dir, focus it.
-- "The same pane" = pane with the user-option `@term=1` set (which we set on creation).
-- Only does anything if nvim is running inside a tmux session.
map("n", "<leader>tt", function()
    if vim.env.TMUX == nil then
        vim.notify("Not running in a tmux session", vim.log.levels.WARN)
        return
    end

    -- Where the file we're editing lives. Fall back to nvim's cwd if no file.
    local bufname = vim.api.nvim_buf_get_name(0)
    local dir = (bufname ~= "" and vim.fn.fnamemodify(bufname, ":p:h")) or vim.fn.getcwd()

    -- Look for an existing @term=1 pane in the current tmux window.
    local pane_id = nil
    local handle = io.popen("tmux list-panes -F '#{pane_id} #{@term}'")
    if handle then
        for line in handle:lines() do
            local id, marker = line:match("(%S+)%s+(%S*)")
            if marker == "1" then
                pane_id = id
                break
            end
        end
        handle:close()
    end

    if pane_id then
        -- Existing pane: cd it (the leading space prevents the cd from polluting
        -- shell history, in zsh/bash with HISTCONTROL=ignorespace) and focus it.
        vim.fn.system({ "tmux", "send-keys", "-t", pane_id,
                        " cd " .. vim.fn.shellescape(dir), "Enter" })
        vim.fn.system({ "tmux", "select-pane", "-t", pane_id })
    else
        -- No pane yet: split below, 10 lines tall, cd'd to dir. Then mark it
        -- with @term=1 so future <leader>tt presses find this same pane.
        vim.fn.system({ "tmux", "split-window", "-v", "-l", "10", "-c", dir })
        vim.fn.system({ "tmux", "set-option", "-p", "@term", "1" })
    end
end, { desc = "tmux terminal that follows the current file's directory" })



-- =============================================================================
-- 4. lazy.nvim bootstrap + plugin load
-- =============================================================================
-- Clones lazy.nvim on first run if it's not already installed. Then prepends
-- it to the runtimepath so `require("lazy")` resolves. Same shape as before;
-- only the bottom line changed (plugin specs moved to lua/plugins.lua).

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Import every plugin spec from lua/plugins.lua.
require("lazy").setup("plugins")
