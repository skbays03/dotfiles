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

-- Insert-mode bracket escapes (using Option/Alt — Ghostty has
-- `macos-option-as-alt = true` so Option-H / Option-L produce M-h / M-l).
--
--   <M-l>  jump PAST the next closing bracket/quote on the current line.
--          Use when typing inside autopairs-inserted (), [], {}, "", ''.
--   <M-h>  jump BEFORE the previous opening bracket/quote on the current line.
--          The mirror of M-l for backing out of a pair.
--
-- C-l / C-h are deliberately NOT used: C-h shares its keycode with Backspace
-- in terminals, and using C-l for one direction without C-h for the other
-- would be asymmetric.
map("i", "<M-l>", function()
    local row    = vim.fn.line(".")
    local col    = vim.fn.col(".")
    local n_rows = vim.api.nvim_buf_line_count(0)

    -- Search current line from cursor onward, then each subsequent line top to bottom.
    for r = row, n_rows do
        local line      = vim.api.nvim_buf_get_lines(0, r - 1, r, false)[1] or ""
        local start_col = (r == row) and col or 1
        for i = start_col, #line do
            local c = line:sub(i, i)
            if c == ")" or c == "]" or c == "}" or c == "\"" or c == "'" then
                -- Position cursor just AFTER the char (0-indexed col = i).
                vim.api.nvim_win_set_cursor(0, { r, i })
                return
            end
        end
    end
end, { desc = "Jump past next closing bracket/quote (multi-line)" })

map("i", "<M-h>", function()
    local row = vim.fn.line(".")
    local col = vim.fn.col(".")

    -- Search current line backwards from before cursor, then each prior line bottom to top.
    for r = row, 1, -1 do
        local line    = vim.api.nvim_buf_get_lines(0, r - 1, r, false)[1] or ""
        local end_col = (r == row) and (col - 1) or #line
        for i = end_col, 1, -1 do
            local c = line:sub(i, i)
            if c == "(" or c == "[" or c == "{" or c == "\"" or c == "'" then
                -- Position cursor just BEFORE the char (0-indexed col = i - 1).
                vim.api.nvim_win_set_cursor(0, { r, i - 1 })
                return
            end
        end
    end
end, { desc = "Jump before previous opening bracket/quote (multi-line)" })

-- Insert-mode line navigation without reaching for arrow keys.
--   <M-j>  cursor DOWN one line
--   <M-k>  cursor UP one line
-- (h/l are bracket-jumping above; j/k are line-jumping here.
--  Together: M+hjkl covers all four directions, no arrow keys needed.)
map("i", "<M-j>", "<Down>", { desc = "Move cursor down one line" })
map("i", "<M-k>", "<Up>",   { desc = "Move cursor up one line" })

-- Word + line-end motions in insert mode (also arrow-free).
--   <M-w>  forward by word    (vim's `w` motion)
--   <M-b>  backward by word   (vim's `b` motion)
--   <M-a>  start of line      (first non-blank — vim's `^`)
--   <M-e>  end of line        (last char — vim's `$`)
-- These use <C-o> which runs ONE normal-mode command then returns to insert.
map("i", "<M-w>", "<C-o>w", { desc = "Insert: next word" })
map("i", "<M-b>", "<C-o>b", { desc = "Insert: previous word" })
map("i", "<M-a>", "<C-o>^", { desc = "Insert: start of line (first non-blank)" })
map("i", "<M-e>", "<C-o>$", { desc = "Insert: end of line" })

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

-- tmux_term — one shell pane below nvim that follows the current file.
-- Module lives in lua/tmux_term.lua. Five bindings:
--   <leader>tt  open/focus pane, cd'd to current file's PARENT DIR
--               (most direct context — "I want to run something against this file")
--   <leader>tT  open/focus pane, cd'd to current file's git PROJECT ROOT
--               (broader context — "make / project-wide commands")
--   <leader>tk  grow the pane to 25 rows (default open height is 10)
--   <leader>tr  in Visual mode: send the selected text to the pane and run it
--   <leader>td  destroy (close) the term pane
local tt = require("tmux_term")
map("n", "<leader>tt", tt.open,         { desc = "tmux term: open (cd to file's parent dir)" })
map("n", "<leader>tT", tt.open_at_root, { desc = "tmux term: open (cd to project root)" })
map("n", "<leader>tk", function() tt.resize(25) end, { desc = "tmux term: grow to 25 rows" })
map("n", "<leader>td", tt.destroy,      { desc = "tmux term: destroy (close pane)" })
map("v", "<leader>tr", function()
    -- Compute the visual selection's line range. Using line("v") + line(".")
    -- avoids polluting any register (vs the more common `normal! y` approach).
    local s, e = vim.fn.line("v"), vim.fn.line(".")
    if s > e then s, e = e, s end
    local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
    tt.run(table.concat(lines, "\n"))
end, { desc = "tmux term: run visual selection" })



-- =============================================================================
-- 4. Autocmds + diagnostic display
-- =============================================================================

-- Filetype-specific indent fix for C / C++.
-- Vim's cindent treats anything ending in `:` as a goto label and outdents it
-- to column 0. That's wrong for C++ scope-resolution (`std::`) — while typing
-- `std:` you see the line jump to col 0, then snap back when you type the
-- second `:`. The L0 cinoption disables that outdent so labels stay at the
-- current indent and `std::` doesn't jump.
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "h", "hpp" },
    callback = function()
        vim.opt_local.cinoptions:append("L0")

        -- Use real tab characters (not spaces) for C/C++. Matches the
        -- .clang-format setting used by format-on-save, so typed indent
        -- and saved indent agree.
        --   tabstop      = visual width of a tab character
        --   shiftwidth   = indent step used by autoindent / >> / <<
        --   softtabstop  = how Backspace/Tab behave near tab characters
        --   expandtab    = OFF (insert real \t, not spaces)
        vim.opt_local.expandtab    = false
        vim.opt_local.tabstop      = 4
        vim.opt_local.shiftwidth   = 4
        vim.opt_local.softtabstop  = 4

        -- Use vim's built-in cindent (C-aware) instead of treesitter's indent
        -- module. The treesitter indent for C/C++ has gaps that produce
        -- "no indent" inside braces from nvim-autopairs's Enter splitter.
        -- cindent has been around forever and indents braces correctly.
        vim.opt_local.cindent      = true
        vim.opt_local.indentexpr   = ""    -- clear treesitter's indentexpr
    end,
})

-- Diagnostic display — VS Code-style inline errors/warnings.
-- The pieces:
--   virtual_text  — the "● message" rendered AFTER each problematic line
--   signs         — gutter icons (Error / Warn / Info / Hint)
--   underline     — squiggle under the offending tokens
--   float         — popup on <leader>e (or hover); rounded border looks nicer
-- update_in_insert = false keeps it quiet while you type; updates after stop.
-- severity_sort orders errors above warnings above info, matching VS Code.
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        spacing = 4,
        source = "if_many",     -- show LSP name only when multiple LSPs are reporting
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = "if_many",
    },
})

-- Auto-format C/C++ files on save via clangd (the LSP-attached formatter).
-- This is the "VS Code-equivalent" of format-on-save. Bypass on any single
-- save with `:noa w` (no autocmds, write) if clangd reformats something you
-- want to keep as-is.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
    callback = function() vim.lsp.buf.format({ async = false }) end,
})

-- Manual format keybind for any file with an attached LSP (Python via pyright,
-- Lua via lua_ls, etc.). For C/C++ this is mostly redundant given save-format
-- above, but handy when you want to reformat without saving.
map("n", "<leader>fm", function() vim.lsp.buf.format({ async = false }) end,
    { desc = "Format buffer via LSP" })



-- =============================================================================
-- 5. lazy.nvim bootstrap + plugin load
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
