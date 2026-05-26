-- =============================================================================
-- lua/plugins.lua — all plugin specs in one file
-- =============================================================================
--
-- Each entry in the returned table is a lazy.nvim plugin spec. Add/remove
-- plugins here, then `:Lazy sync` (or just restart nvim) to apply.
--
-- Plugin categories (in order below):
--   - Theme:        tokyonight
--   - Learning aid: which-key
--   - UI:           lualine (statusline)
--   - Finder:       telescope (with plenary dep)
--   - Explorer:     neo-tree (sidebar file tree)
--   - Syntax:       nvim-treesitter
--   - Editing:      Comment.nvim
--   - LSP stack:    mason + mason-lspconfig + nvim-lspconfig
--   - Completion:   nvim-cmp + cmp-nvim-lsp + cmp-buffer + cmp-path
--   - Practice:     vim-be-good (kept from your prior config)
-- =============================================================================

return {

    -- =========================================================================
    -- Theme — tokyonight-night
    -- =========================================================================
    -- `lazy = false` + `priority = 1000` makes this load FIRST, before any
    -- other plugin tries to read the colorscheme.
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "night",
                transparent = true,                  -- let the Ghostty wallpaper show through
                styles = {
                    sidebars = "transparent",         -- neo-tree, etc.
                    floats = "transparent",           -- which-key, telescope previews, LSP hover
                },
            })
            vim.cmd("colorscheme tokyonight-night")

            -- Override neo-tree's "(N hidden items)" + other dim meta text.
            -- tokyonight defaults these to the gutter color (#3b4261),
            -- which disappears against the transparent wallpaper background.
            -- Use a muted-but-readable blue-grey + italic to flag "meta info".
            vim.api.nvim_set_hl(0, "NeoTreeMessage", { fg = "#9aa5ce", italic = true })
            vim.api.nvim_set_hl(0, "NeoTreeDimText", { fg = "#9aa5ce", italic = true })

            -- Brighten Comment from tokyonight-night's default (#565f89, hard to
            -- read on a dark wallpaper) to the same muted blue as the meta text.
            vim.api.nvim_set_hl(0, "Comment", { fg = "#9aa5ce", italic = true })
        end,
    },

    -- =========================================================================
    -- which-key — popup that shows pending keybindings as you type
    -- =========================================================================
    -- THE single biggest learning aid for any vim newcomer. Press <leader>
    -- (space) and wait 300ms; a popup shows every binding under that prefix.
    -- Same for any partial sequence (e.g., `g`, `<C-w>`).
    {
        "folke/which-key.nvim",
        event = "VeryLazy",     -- load after UI is ready (faster startup)
        opts = {},              -- default config is good
    },

    -- =========================================================================
    -- alpha-nvim — start screen / dashboard shown when nvim opens with no file
    -- =========================================================================
    -- Replaces the empty buffer at startup with an ASCII header + menu of
    -- common actions. Press the letter shown on each button to fire its action.
    -- Disappears once you open any buffer; never gets in your way after that.
    --
    -- Customize the header (any 6-line ASCII), buttons (any nvim command), and
    -- footer (string or function). Reload with :Lazy reload alpha-nvim.
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local alpha     = require("alpha")
            local dashboard = require("alpha.themes.dashboard")

            -- ---- Header ---------------------------------------------------------
            -- "shawn" in ANSI Shadow font. Swap in any 6-line ASCII art.
            -- Generators: https://patorjk.com/software/taag/ (ANSI Shadow style).
            dashboard.section.header.val = {
                [[ ███████╗██╗  ██╗ █████╗ ██╗    ██╗███╗   ██╗ ]],
                [[ ██╔════╝██║  ██║██╔══██╗██║    ██║████╗  ██║ ]],
                [[ ███████╗███████║███████║██║ █╗ ██║██╔██╗ ██║ ]],
                [[ ╚════██║██╔══██║██╔══██║██║███╗██║██║╚██╗██║ ]],
                [[ ███████║██║  ██║██║  ██║╚███╔███╔╝██║ ╚████║ ]],
                [[ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝ ]],
            }
            dashboard.section.header.opts.hl = "Type"  -- inherit theme accent color

            -- ---- Buttons --------------------------------------------------------
            -- First arg = shortcut key (press the letter to fire). The icon
            -- glyphs come from your Nerd Font; pick others from nerdfonts.com.
            dashboard.section.buttons.val = {
                dashboard.button("f", "  Find file",        ":Telescope find_files<CR>"),
                dashboard.button("r", "  Recent files",     ":Telescope oldfiles<CR>"),
                dashboard.button("g", "  Live grep",        ":Telescope live_grep<CR>"),
                dashboard.button("e", "  File explorer",   ":Neotree<CR>"),
                dashboard.button("n", "  New file",         ":enew<CR>"),
                dashboard.button("c", "  Edit config",     ":e ~/.config/nvim/init.lua<CR>"),
                dashboard.button("l", "󰒲  Plugins (Lazy)",   ":Lazy<CR>"),
                dashboard.button("?", "  Browse keymaps",  ":Telescope keymaps<CR>"),
                dashboard.button("q", "  Quit",             ":qa<CR>"),
            }

            -- ---- Footer ---------------------------------------------------------
            -- Shows plugin count + startup time once lazy.nvim has stats.
            local function footer()
                local ok, lazy = pcall(require, "lazy")
                if not ok then return "" end
                local stats = lazy.stats()
                local ms = math.floor(stats.startuptime + 0.5)
                return string.format("  %d plugins loaded in %d ms", stats.loaded, ms)
            end
            dashboard.section.footer.val = footer()
            dashboard.section.footer.opts.hl = "Comment"

            alpha.setup(dashboard.opts)
        end,
    },

    -- =========================================================================
    -- lualine — status line at the bottom of the window
    -- =========================================================================
    -- Replaces the boring default with a colored bar showing mode, file,
    -- git branch, diagnostics, filetype, position. Matches the theme.
    {
        "nvim-lualine/lualine.nvim",
        opts = { options = { theme = "tokyonight" } },
    },

    -- =========================================================================
    -- telescope — fuzzy finder for files, buffers, live grep, etc.
    -- =========================================================================
    -- The single most-used plugin in the modern nvim world. Press the keys
    -- below; type to filter; <CR> to open.
    --
    -- Note: live_grep needs `ripgrep` (rg) installed system-wide for grep
    -- performance. find_files prefers `fd` over the built-in find. If you
    -- don't have them yet:  brew install ripgrep fd
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        cmd = "Telescope",        -- :Telescope ... triggers lazy-load (needed by alpha dashboard buttons)
        dependencies = { "nvim-lua/plenary.nvim" },  -- required utility lib
        opts = {
            defaults = {
                preview = {
                    -- Workaround: nvim 0.12.2's built-in treesitter triggers a
                    -- "attempt to call method 'range' (a nil value)" error when
                    -- the markdown injection query runs on certain previews.
                    -- Disabling treesitter in previews falls back to vim's regex
                    -- syntax highlighting (slightly less colorful, but no errors).
                    -- The actual editor buffers still use treesitter normally.
                    treesitter = false,
                },
            },
        },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Fuzzy file finder" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>",  desc = "Live grep (needs ripgrep)" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>",    desc = "Open buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>",  desc = "Help tags" },
            { "<leader>fr", "<cmd>Telescope oldfiles<CR>",   desc = "Recent files" },
            { "<leader>fk", "<cmd>Telescope keymaps<CR>",    desc = "Browse all keymaps" },
            { "<leader>?",  "<cmd>Telescope keymaps<CR>",    desc = "Browse all keymaps (alias)" },
        },
    },

    -- =========================================================================
    -- neo-tree — sidebar file tree (VS Code-style)
    -- =========================================================================
    -- A persistent left-sidebar showing your project's directory structure.
    -- Browse with j/k, <CR> opens a file in the main editor window.
    --
    -- Keymap: <leader>n toggles the tree open/closed.
    -- Inside the tree: <CR>=open, a=add file, d=delete, r=rename, R=refresh,
    -- H=toggle hidden files, .=set as root. Press ? inside the tree to see all.
    --
    -- Composes with telescope: tree for browsing, telescope (<leader>ff/fg) for
    -- searching when you know what you're looking for.
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        cmd = "Neotree",          -- :Neotree ... triggers lazy-load (needed by alpha dashboard buttons)
        dependencies = {
            "nvim-lua/plenary.nvim",          -- shared util lib (already a dep of telescope)
            "nvim-tree/nvim-web-devicons",    -- file-type icons (needs your Nerd Font)
            "MunifTanjim/nui.nvim",           -- UI primitives neo-tree uses
        },
        keys = {
            { "<leader>n", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
        },
        opts = {
            close_if_last_window = true,      -- auto-close nvim if tree is the only window
            sort_case_insensitive = true,     -- 'README.md' next to 'readme_old.md', not separated
            -- Default sort = "order by type": directories first, then files
            -- grouped by extension (all .hpp together, all .cpp together, etc.),
            -- ties broken by name. Same as pressing `ot` inside the tree, but
            -- applied automatically on every open.
            sort_function = function(a, b)
                -- Directories above files.
                if a.type ~= b.type then
                    return a.type == "directory"
                end
                -- Same type — for files, sort by extension first.
                if a.type == "file" then
                    local ext_a = a.name:match("%.[^.]+$") or ""
                    local ext_b = b.name:match("%.[^.]+$") or ""
                    if ext_a ~= ext_b then return ext_a < ext_b end
                end
                -- Final tiebreak: case-insensitive name.
                return a.name:lower() < b.name:lower()
            end,
            window = {
                width = 35,
                mappings = {
                    ["<space>"] = "none",     -- keep <space> as leader, even inside tree
                },
            },
            filesystem = {
                follow_current_file = { enabled = true },   -- highlight the file you're editing
                use_libuv_file_watcher = true,              -- auto-refresh on filesystem changes
            },
        },
    },

    -- =========================================================================
    -- nvim-treesitter — modern syntax highlighting + indent
    -- =========================================================================
    -- Replaces vim's old regex-based highlighter with a real parser per
    -- language. Highlights are far more accurate; downstream plugins (like
    -- text-object plugins) use the parse tree too.
    --
    -- IMPORTANT: pinned to `branch = "master"`. The plugin's default branch
    -- is now `main`, which has a completely different API (no `configs.setup`
    -- entry point, no `ensure_installed`). The `master` branch is the stable,
    -- well-documented API every tutorial assumes — we use that.
    --
    -- `:TSUpdate` runs on install and downloads + compiles parsers for the
    -- languages listed below. First launch will take a few seconds.
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
        opts = {
            ensure_installed = {
                "lua", "vim", "vimdoc",            -- your config + docs
                "c", "cpp",                         -- sift
                "python",                           -- cs-prep
                "bash", "markdown", "json",         -- everyday
            },
            highlight = { enable = true },
            indent = { enable = true },
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },

    -- =========================================================================
    -- Comment.nvim — gcc to comment a line, gc{motion} to comment a range
    -- =========================================================================
    -- The standard commenting plugin. Examples:
    --   gcc        comment/uncomment the current line
    --   gc3j       comment current line + next 3 lines
    --   gcap       comment the surrounding paragraph
    --   gc (visual) comment the visual selection
    {
        "numToStr/Comment.nvim",
        opts = {},
        event = "VeryLazy",
    },

    -- =========================================================================
    -- LSP stack — mason installs servers, lspconfig wires them to nvim
    -- =========================================================================
    -- Three plugins working together:
    --   mason.nvim          — a package manager for LSP servers, linters,
    --                          formatters. Installs them into nvim's data dir.
    --   mason-lspconfig     — bridge between mason and lspconfig (auto-installs
    --                          listed servers via mason).
    --   nvim-lspconfig      — the actual LSP client config; tells nvim how to
    --                          start each server and what to do with results.
    --
    -- After first launch:  :Mason  shows the package list. The servers below
    -- (clangd, pyright, lua_ls) will auto-install on first launch. If clangd
    -- fails to install via mason (the macOS binary download can be flaky),
    -- run:  brew install llvm  and add /opt/homebrew/opt/llvm/bin to PATH.
    {
        "williamboman/mason.nvim",
        opts = {},
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            -- mason-lspconfig v2.0+: ensure_installed is the only field needed
            -- here. `automatic_installation` was deprecated (redundant with
            -- ensure_installed). We handle enable ourselves below for clarity.
            ensure_installed = { "clangd", "pyright", "lua_ls" },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp" },   -- so LSP knows cmp's capabilities
        config = function()
            -- ---------- LSP config (nvim 0.11+ API) ------------------------
            -- The old `require("lspconfig").X.setup({...})` framework is
            -- deprecated and will be removed in nvim-lspconfig v3.0. Replaced by:
            --   vim.lsp.config('servername', {...})  — define / override config
            --   vim.lsp.enable({'servername'})       — start the server
            --
            -- nvim-lspconfig (the plugin) still ships per-server defaults in
            -- its lsp/ directory, which nvim 0.11+ auto-discovers. Our
            -- vim.lsp.config() calls MERGE on top of those defaults.

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Wildcard config: apply nvim-cmp's capabilities to EVERY server.
            -- Saves repeating `capabilities = capabilities` per server.
            vim.lsp.config("*", { capabilities = capabilities })

            -- Per-server overrides. Each call merges with the wildcard above
            -- AND with nvim-lspconfig's shipped default.
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },   -- silence "vim is undefined"
                    },
                },
            })

            -- Enable the servers we want. mason installs the binaries (via
            -- mason-lspconfig's ensure_installed); we just turn them on.
            vim.lsp.enable({ "clangd", "pyright", "lua_ls" })

            -- ---------- LspAttach: buffer-local keymaps --------------------
            -- This API is stable across nvim versions. Fires once per buffer
            -- per server attach; we register the keys scoped to that buffer.
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local bufopts = { buffer = args.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition,  vim.tbl_extend("force", bufopts, { desc = "Go to definition" }))
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", bufopts, { desc = "Go to declaration" }))
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", bufopts, { desc = "Find references" }))
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", bufopts, { desc = "Go to implementation" }))
                    vim.keymap.set("n", "K",  vim.lsp.buf.hover,       vim.tbl_extend("force", bufopts, { desc = "Hover docs" }))
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", bufopts, { desc = "Rename symbol" }))
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", bufopts, { desc = "Code action" }))
                    vim.keymap.set("n", "<leader>e",  vim.diagnostic.open_float, vim.tbl_extend("force", bufopts, { desc = "Show diagnostic" }))
                end,
            })
        end,
    },

    -- =========================================================================
    -- nvim-cmp — completion engine with LSP / buffer / path sources
    -- =========================================================================
    -- The popup menu you see as you type. Sources (one entry per backend):
    --   cmp-nvim-lsp  — completions from your language servers
    --   cmp-buffer    — words from currently open buffers (cheap, useful fallback)
    --   cmp-path      — file paths after `/` or `./`
    --
    -- Keys (in insert mode while menu is open):
    --   <Tab> / <S-Tab>  cycle through suggestions
    --   <CR>             accept the current/first suggestion
    --   <C-Space>        manually trigger the menu
    --   <C-e>            close the menu without inserting anything
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",   -- load on first insert-mode entry (faster startup)
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"]     = cmp.mapping.abort(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = true }),   -- accept selection (or first item)
                    ["<Tab>"]     = cmp.mapping.select_next_item(),
                    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- =========================================================================
    -- nvim-autopairs — auto-insert closing braces / parens / quotes
    -- =========================================================================
    -- Type `{` → get `{|}` (cursor between). Press Enter → 3-line block with
    -- the cursor on the middle line, indented. This is the missing piece
    -- between vim's cindent and VS Code's "Enter inside braces" experience.
    --
    -- treesitter-aware (won't pair inside strings/comments). Integrated with
    -- nvim-cmp so confirming a completion that ends in `(` also handles the
    -- parens correctly.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        dependencies = { "hrsh7th/nvim-cmp" },
        config = function()
            require("nvim-autopairs").setup({
                check_ts = true,   -- treesitter-aware
            })
            -- Wire to nvim-cmp's confirm event so completions that produce
            -- callable signatures (like func()) get the parens-pair treatment.
            local ok_cmp,   cmp        = pcall(require, "cmp")
            local ok_pairs, pairs_cmp  = pcall(require, "nvim-autopairs.completion.cmp")
            if ok_cmp and ok_pairs then
                cmp.event:on("confirm_done", pairs_cmp.on_confirm_done())
            end
        end,
    },

    -- =========================================================================
    -- lazygit.nvim — wrap the lazygit TUI in a floating nvim window
    -- =========================================================================
    -- <leader>lg opens lazygit over the current nvim window. Inside lazygit:
    --   space     stage / unstage the hunk/file under cursor
    --   c         commit (opens a commit-message buffer; close it to finish)
    --   P         push
    --   p         pull
    --   <Enter>   view diff / drill in
    --   q         close lazygit + return to nvim
    --   ?         full help (every keybind lazygit supports)
    --
    -- The c "msg" shell alias is still great for "one-line commit, ship it."
    -- lazygit is for cases where you want to SEE the diff, stage individual
    -- hunks, or do anything more involved than a quick commit.
    --
    -- The nvim plugin is tiny; it just embeds the lazygit binary (which is
    -- the actual engine — installed via brew on Mac / apt on Linux).
    {
        "kdheepak/lazygit.nvim",
        cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile",
                "LazyGitFilter", "LazyGitFilterCurrentFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>",            desc = "LazyGit (project root)" },
            { "<leader>lf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file's repo)" },
        },
    },

    -- =========================================================================
    -- vim-be-good (kept from your prior config) — vim-motion practice game
    -- =========================================================================
    -- Lazy-loaded; only attaches when you run :VimBeGood.
    { "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },

}
