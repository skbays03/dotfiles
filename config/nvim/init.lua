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

-- Insert-mode cursor movement on the home row (Ghostty has
-- `macos-option-as-alt = true` so Option-X produces <M-X>).
-- Mirrors hjkl from normal/visual: left, down, up, right — one char
-- or one line per press. Lets us move around mid-insert without
-- reaching for arrows or dropping back to normal mode.
map("i", "<M-h>", "<Left>",  { desc = "Move cursor left one char" })
map("i", "<M-j>", "<Down>",  { desc = "Move cursor down one line" })
map("i", "<M-k>", "<Up>",    { desc = "Move cursor up one line" })
map("i", "<M-l>", "<Right>", { desc = "Move cursor right one char" })

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

-- <leader>k — define the word/acronym under the cursor via the `dict` client.
-- Tries FOLDOC (computing definitions), then VERA (computing-acronym
-- expansions); both are purpose-built for tech terms (KDF, FQDN, AEAD, ...).
-- Shows the result in a float. Needs the `dict` CLI; degrades to a notify.
map("n", "<leader>k", function()
    if vim.fn.executable("dict") == 0 then
        vim.notify("`dict` not found — install it (brew install dict).",
                   vim.log.levels.WARN)
        return
    end
    local word = vim.fn.expand("<cword>")
    if word == "" then return end
    local out = vim.fn.systemlist({ "dict", "-d", "foldoc", word })
    if vim.v.shell_error ~= 0 or #out == 0 then
        out = vim.fn.systemlist({ "dict", "-d", "vera", word })
    end
    if vim.v.shell_error ~= 0 or #out == 0 then
        vim.notify("No definition for '" .. word .. "'.", vim.log.levels.INFO)
        return
    end
    vim.lsp.util.open_floating_preview(out, "plaintext",
        { border = "rounded", max_width = 80 })
end, { desc = "Define word/acronym under cursor (dict)" })

-- <leader>s — insert filetype skeleton.
-- Looks for ~/.config/nvim/templates/<extension>.skel FIRST, then falls
-- back to <filetype>.skel. The extension check lets us distinguish .hpp
-- from .cpp (both share filetype "cpp") so hpp.skel and cpp.skel can be
-- different. Reads in AT the current line (pushing the current line down);
-- for a freshly opened empty file the template starts at line 1, not 2.
-- Drop new template files in that dir for any extension or filetype
-- (python.skel, hpp.skel, sh.skel, ...).
map("n", "<leader>s", function()
    local ext = vim.fn.expand("%:e")
    local ft = vim.bo.filetype
    local templates_dir = vim.fn.stdpath("config") .. "/templates/"

    -- Try extension first (e.g., hpp → hpp.skel), then filetype as fallback
    -- (e.g., python filetype → python.skel when extension was .py).
    local template = nil
    if ext ~= "" then
        local by_ext = templates_dir .. ext .. ".skel"
        if vim.fn.filereadable(by_ext) == 1 then
            template = by_ext
        end
    end
    if template == nil and ft ~= "" then
        local by_ft = templates_dir .. ft .. ".skel"
        if vim.fn.filereadable(by_ft) == 1 then
            template = by_ft
        end
    end
    if template == nil then
        vim.notify("No template for extension '" .. ext .. "' or filetype '"
                   .. ft .. "'.", vim.log.levels.WARN)
        return
    end

    -- Snapshot whether the buffer was effectively empty (just one empty
    -- line — the state of a freshly opened file). If so, the original
    -- blank line-1 will end up trailing after the insert, and we trim it.
    local was_empty = (vim.fn.line("$") == 1 and vim.fn.getline(1) == "")

    -- Record cursor position so we can snap back to the START of the
    -- inserted template after the read (vim's default is to land at the
    -- LAST inserted line, which is rarely what you want here).
    local original_line = vim.fn.line(".")

    -- `(N-1)read FILE` inserts AT the cursor line (pushing current line down).
    -- At line 1 this evaluates to `0read` which inserts at the very top.
    -- math.max(0, ...) defends against a pathological zero-line buffer where
    -- line(".") returns 0 and (0-1) would be an invalid -1 range.
    local insert_after = math.max(0, original_line - 1)
    vim.cmd(insert_after .. "read " .. template)

    -- Trim the trailing leftover empty line that was the original blank line-1.
    if was_empty and vim.fn.getline("$") == "" then
        vim.cmd("$delete _")
    end

    -- Snap cursor back to the start of the inserted template. If the buffer
    -- was effectively empty (or actually empty in the line=0 case), that's
    -- line 1; otherwise it's the line the user was on when they triggered.
    local target_line = math.max(1, original_line)
    vim.api.nvim_win_set_cursor(0, {target_line, 0})
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
-- Rust uses 2-space indent (matches rustfmt.toml: tab_spaces = 2), spaces not
-- tabs — so typed/autoindent agrees with what `cargo fmt` / <leader>cf produce
-- and you don't get a 4-space jump the formatter then rewrites.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function()
        vim.opt_local.expandtab   = true
        vim.opt_local.tabstop     = 2
        vim.opt_local.shiftwidth  = 2
        vim.opt_local.softtabstop = 2
    end,
})

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

-- Color the border on floating windows (LSP hover, diagnostic float, code
-- actions, etc.). FloatBorder is the highlight group every bordered floating
-- window uses. Re-applies on every ColorScheme event so it survives
-- colorscheme changes / re-applications.
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
    end,
})
-- Also apply immediately for current colorscheme (autocmd only fires on
-- FUTURE ColorScheme events).
vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })

-- LSP popup borders — apply rounded borders to every LSP-rendered floating
-- window by wrapping the default handlers with `border = "rounded"`.
-- Covers: hover (K), signature help (during typing in function calls).
-- The diagnostic float (<leader>e) already has border configured above via
-- vim.diagnostic.config. The code-action menu + rename use vim.ui.select /
-- vim.ui.input which honor their own theming (dressing.nvim would
-- standardize those, but native nvim doesn't apply border there).
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
    vim.lsp.handlers.hover, { border = "rounded" }
)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
    vim.lsp.handlers.signature_help, { border = "rounded" }
)

-- :Sessions — list saved persistence.nvim sessions with their decoded
-- directory paths. Sessions are stored at ~/.local/state/nvim/sessions/
-- with `/` in directory paths url-encoded to `%`. This command decodes
-- them back for readability.
vim.api.nvim_create_user_command("Sessions", function()
    local sessions_dir = vim.fn.stdpath("state") .. "/sessions"
    local files = vim.fn.glob(sessions_dir .. "/*.vim", false, true)
    if #files == 0 then
        print("No saved sessions in " .. sessions_dir)
        return
    end
    print("Sessions in " .. sessions_dir .. ":")
    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")   -- basename without extension
        local decoded = name:gsub("%%", "/")             -- decode % back to /
        print("  " .. decoded)
    end
end, { desc = "List saved sessions" })

-- Auto-format C/C++ files on save — DISABLED (2026-05-31).
-- Was triggering reformats that conflicted with hand-tuned comment layouts
-- and project-specific spacing choices. Manual format remains available via
-- the `<leader>fm` keybind below for when you actually want to reformat.
-- To re-enable, uncomment the block.
--
-- vim.api.nvim_create_autocmd("BufWritePre", {
--     pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
--     callback = function() vim.lsp.buf.format({ async = false }) end,
-- })

-- Manual format keybind for any file with an attached LSP (Python via pyright,
-- Lua via lua_ls, etc.). For C/C++ this is mostly redundant given save-format
-- above, but handy when you want to reformat without saving.
map("n", "<leader>fm", function() vim.lsp.buf.format({ async = false }) end,
    { desc = "Format buffer via LSP" })

-- Format current file via external formatter, picked by file extension.
-- Mirrors the leader-s skeleton-insert pattern: extension lookup, fall back
-- to filetype, notify on miss. More predictable than <leader>fm for languages
-- where the LSP either doesn't format (e.g. pyright) or formats with a tool
-- other than the project-configured one.
map("n", "<leader>cf", function()
    local ext  = vim.fn.expand("%:e")
    local ft   = vim.bo.filetype
    local file = vim.fn.expand("%:p")

    -- Extension -> argv. Add new languages here as needed.
    local formatters = {
        cpp  = { "clang-format", "-i", file },
        hpp  = { "clang-format", "-i", file },
        cc   = { "clang-format", "-i", file },
        h    = { "clang-format", "-i", file },
        c    = { "clang-format", "-i", file },
        py   = { "ruff", "format", file },
        lua  = { "stylua", file },
        sh   = { "shfmt", "-w", file },
        -- Bare rustfmt parses as edition 2015 and does NOT read Cargo.toml
        -- (only `cargo fmt` does, but that's project-wide) — pin the edition.
        rs   = { "rustfmt", "--edition", "2024", file },
    }

    -- Filetype fallback for files without standard extensions
    -- (e.g. CMakeLists.txt, .zshrc).
    local by_filetype = {
        cmake = { "cmake-format", "-i", file },
    }

    local cmd = formatters[ext] or by_filetype[ft]
    if not cmd then
        vim.notify("No formatter for ." .. ext .. " (filetype " .. ft .. ")",
                   vim.log.levels.WARN)
        return
    end

    -- Save first; formatters work on disk content, not buffer state.
    vim.cmd("silent! write")

    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        vim.notify("Format failed: " .. out, vim.log.levels.ERROR)
        return
    end

    -- Reload to pick up the formatter's writes.
    vim.cmd("edit!")
end, { desc = "Format current file (by extension)" })



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
