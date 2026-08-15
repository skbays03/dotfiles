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
    -- Keymap: <leader>n focuses the tree (opens if needed; closes if already focused).
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
            { "<leader>n", function()
                if vim.bo.filetype == "neo-tree" then
                    vim.cmd("Neotree close")
                else
                    vim.cmd("Neotree focus")
                end
            end, desc = "Focus / close file tree" },
        },
        opts = {
            close_if_last_window = true,      -- auto-close nvim if tree is the only window
            -- Default sort = "order by type": directories first, then files
            -- grouped by extension (all .hpp together, all .cpp together, etc.),
            -- ties broken by case-insensitive name. Same as pressing `ot`
            -- inside the tree, but applied automatically on every open.
            --
            -- Defensive: neo-tree occasionally passes special node types
            -- (e.g., "message" for the "(N hidden items)" line), or partially-
            -- populated nodes. Guard against missing fields so the sort
            -- doesn't throw and break the whole tree render.
            sort_function = function(a, b)
                if not a or not b then return false end
                local an, bn = a.name or "", b.name or ""
                local at, bt = a.type or "", b.type or ""
                -- Directories above files.
                if at ~= bt then
                    if at == "directory" then return true end
                    if bt == "directory" then return false end
                end
                -- For regular files, sort by extension first.
                if at == "file" then
                    local ext_a = an:match("%.[^.]+$") or ""
                    local ext_b = bn:match("%.[^.]+$") or ""
                    if ext_a ~= ext_b then return ext_a < ext_b end
                end
                -- Final tiebreak: case-insensitive name.
                return an:lower() < bn:lower()
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
    -- persistence.nvim — session save/restore across nvim restarts
    -- =========================================================================
    -- Saves a session per directory on nvim exit; restore via keymap. Survives
    -- kernel reboots, config reloads, plugin reinstalls. One session per
    -- project working directory — opening nvim in ~/Desktop/projects/one_dash
    -- gets a different session than opening it in ~/dotfiles.
    --
    -- Sessions live at vim.fn.stdpath("state") .. "/sessions/", which is
    -- typically ~/.local/state/nvim/sessions/<encoded-dir-path>.vim
    --
    -- Use :Sessions (defined in init.lua) to see what sessions exist + which
    -- directory each maps to.
    {
        "folke/persistence.nvim",
        event = "BufReadPre",   -- load early to catch initial buffers
        opts = {
            options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
        },
        keys = {
            { "<leader>qs", function() require("persistence").load() end,
                desc = "Restore session for this directory" },
            { "<leader>ql", function() require("persistence").load({ last = true }) end,
                desc = "Restore last session (any directory)" },
            { "<leader>qd", function() require("persistence").stop() end,
                desc = "Don't save current session on exit" },
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
            indent = {
                enable = true,
                -- Treesitter's C/C++ indent module has gaps that produce no-indent
                -- inside braces (especially with nvim-autopairs's Enter splitter).
                -- Fall back to vim's reliable cindent for C/C++; treesitter still
                -- handles indent for Lua/Python/etc.
                disable = { "c", "cpp" },
            },
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
        -- Load before any buffer's FileType event fires, so vim.lsp.enable()
        -- has registered its autocmd in time for the buffer to attach. Without
        -- this, lazy.nvim defers loading to VeryLazy — too late, the first
        -- buffer's FileType has already fired with no handler registered.
        event = { "BufReadPre", "BufNewFile" },
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

            -- slangd — slang's own LSP daemon, ships in the slang prebuilt
            -- tarball (~/.local/share/slang-X.Y.Z/bin/slangd, symlinked into
            -- ~/.local/bin). NOT in mason; installed manually via slang's
            -- GitHub release (see scripts/bootstrap.py in one_dash for the
            -- exact ritual). Slang's parser accepts HLSL by default, so the
            -- same daemon serves both .slang and .hlsl files.
            vim.lsp.config("slangd", {
                cmd          = { "slangd" },
                filetypes    = { "slang", "hlsl" },
                root_markers = { ".git", "CMakeLists.txt" },
            })

            -- nvim doesn't detect .hlsl as a filetype by default; map it.
            vim.filetype.add({ extension = { hlsl = "hlsl" } })

            -- clangd flags — enable the include-discovery workflow.
            --   --header-insertion=iwyu        offer "Add include" code actions
            --                                   on undefined symbols; auto-insert
            --                                   on completion accept
            --   --all-scopes-completion        surface symbols from unimported
            --                                   headers (so `vector` suggests
            --                                   `std::vector` even without
            --                                   <vector> included yet)
            --   --background-index             build + persist a project-wide
            --                                   symbol index so include
            --                                   suggestions actually know where
            --                                   symbols live (first index of a
            --                                   codebase takes ~30s; cached to
            --                                   disk afterwards)
            --   --completion-style=detailed    show full signatures in the
            --                                   completion popup
            --   --clang-tidy                   surface .clang-tidy diagnostics
            --                                   inline
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--header-insertion=iwyu",
                    "--all-scopes-completion",
                    "--background-index",
                    "--completion-style=detailed",
                    "--clang-tidy",
                },
            })

            -- Enable the servers we want. mason installs the binaries (via
            -- mason-lspconfig's ensure_installed); slangd and rust_analyzer
            -- are the exceptions — slangd is system-installed from upstream,
            -- rust-analyzer is a rustup component (version-locked to the
            -- toolchain; `rustup component add rust-analyzer`). We just turn
            -- them on either way.
            vim.lsp.enable({ "clangd", "pyright", "lua_ls", "slangd", "rust_analyzer" })

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
                    vim.keymap.set("n", "K", function()
                        vim.lsp.buf.hover({ border = "rounded" })
                    end, vim.tbl_extend("force", bufopts, { desc = "Hover docs" }))
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", bufopts, { desc = "Rename symbol" }))
                    vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", bufopts, { desc = "Rename symbol (LSP)" }))
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
                    -- Enter: confirm completion ONLY if menu is open AND an item
                    -- is explicitly selected. Otherwise fall through so
                    -- nvim-autopairs can do its brace-split-on-Enter trick.
                    -- `select = false` keeps Enter from auto-confirming the
                    -- first item — that's <Tab>'s job.
                    ["<CR>"]      = cmp.mapping(function(fallback)
                        if cmp.visible() and cmp.get_selected_entry() then
                            cmp.confirm({ select = false })
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<Tab>"]     = cmp.mapping.select_next_item(),
                    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                }),
                -- Size discipline. rust-analyzer sends far richer completion
                -- payloads than clangd/pyright (full generic signatures + whole
                -- rustdoc pages), which let the menu sprawl off-screen and the
                -- docs float collide with it. Entry text is truncated here;
                -- the docs window is bounded below.
                formatting = {
                    format = function(_, item)
                        local function cap(s, n)
                            if s and vim.fn.strchars(s) > n then
                                return vim.fn.strcharpart(s, 0, n - 1) .. "…"
                            end
                            return s
                        end
                        item.abbr = cap(item.abbr, 40)  -- the completion text
                        item.menu = cap(item.menu, 30)  -- the signature/source tag
                        return item
                    end,
                },
                -- Rounded borders on both popups (the completion list AND the
                -- per-entry documentation panel). `FloatBorder:FloatBorder`
                -- links cmp's border to the global FloatBorder highlight group
                -- so the color matches LSP hover / diagnostic float / signature
                -- help (all tokyonight blue via init.lua).
                window = {
                    completion = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                    }),
                    documentation = cmp.config.window.bordered({
                        border = "rounded",
                        max_width = 60,
                        max_height = 14,
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                    }),
                },
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
    -- dressing.nvim — float-window borders for vim.ui.select / vim.ui.input
    -- =========================================================================
    -- Code action menu (<leader>ca) and rename input (<leader>cr / <leader>rn)
    -- use vim.ui.select + vim.ui.input under the hood. Native nvim renders
    -- these inline (no border, no consistent theming). dressing hooks both
    -- and re-renders as floating windows with rounded borders that inherit
    -- the global FloatBorder highlight (tokyonight blue, set in init.lua).
    --
    -- Net effect: every popup in the editor — hover, signature, diagnostic,
    -- completion, code action, rename — gets the same border + color.
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",   -- only loads when first vim.ui call happens
        opts = {
            input = {
                border = "rounded",
                win_options = {
                    winblend = 0,
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                },
            },
            select = {
                backend = { "builtin" },   -- floating window over fzf/telescope so style is consistent
                builtin = {
                    border = "rounded",
                    win_options = {
                        winblend = 0,
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                    },
                },
            },
        },
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

    -- =========================================================================
    -- render-markdown.nvim — in-buffer markdown rendering
    -- =========================================================================
    -- Renders markdown directly inside nvim — no browser, no popup. Headings
    -- get bold styling + indent, code blocks get a subtle background, tables
    -- align properly, checkboxes become glyphs. Stays out of your way: the
    -- underlying buffer is still plain markdown; the rendering is a visual
    -- overlay (so `dd` deletes the actual markdown line, not the rendered
    -- look).
    --
    -- Auto-loads on any .md filetype. Toggle off with `:RenderMarkdown disable`
    -- (re-enable with `:RenderMarkdown enable`).
    --
    -- Depends on nvim-treesitter (already in this config) for the markdown
    -- parser. Lazy `:Lazy sync` after first install to fetch the plugin.
    -- MAINTENANCE NOTE: nvim-treesitter master (≤ cf12346a, 2026-03-23)
    -- pre-dates nvim 0.12's TSNode[] query-match API change. Six handlers
    -- in nvim-treesitter/lua/nvim-treesitter/query_predicates.lua call
    -- match[id] expecting a single TSNode, but nvim 0.12 returns a list.
    -- The crash surfaces as:
    --     "attempt to call method 'range' (a nil value)"
    -- when render-markdown parses a fenced code block (uses the
    -- `set-lang-from-info-string!` directive).
    --
    -- Fix: six in-place `if type(node) == "table" then node = node[#node] end`
    -- guards added to query_predicates.lua, marked `-- LOCAL PATCH`. The
    -- patch lives in ~/.local/share/nvim/lazy/nvim-treesitter/ and will be
    -- OVERWRITTEN by `:Lazy update nvim-treesitter` or `:TSUpdate`. After
    -- those, re-grep for "LOCAL PATCH" — if missing, re-apply (or migrate
    -- to nvim-treesitter's `main` branch once we're ready to validate it).
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        ft = { "markdown" },
        opts = {
            heading = { sign = false },     -- skip the gutter sign column (cleaner)
            code    = { width = "block" },  -- code blocks span available width with bg
        },
    },

    -- Peek: show a symbol's definition / implementation / references in a
    -- floating window WITHOUT leaving your spot (no gd + <C-o> jumplist
    -- churn). Same LSP machinery as `K` hover, but the payload is the
    -- definition's source. The float is a real, editable window — run gd
    -- inside it for a nested peek; <leader>pc closes every open peek.
    {
        "rmagatti/goto-preview",
        keys = {
            { "<leader>pd", function() require("goto-preview").goto_preview_definition() end,      desc = "Peek definition" },
            { "<leader>pi", function() require("goto-preview").goto_preview_implementation() end,  desc = "Peek implementation" },
            { "<leader>pt", function() require("goto-preview").goto_preview_type_definition() end, desc = "Peek type definition" },
            { "<leader>pr", function() require("goto-preview").goto_preview_references() end,       desc = "Peek references" },
            { "<leader>pc", function() require("goto-preview").close_all_win() end,                desc = "Close all peeks" },
        },
        config = function()
            require("goto-preview").setup({
                width = 100,              -- float width in columns
                height = 20,              -- float height in rows
                default_mappings = false, -- we define our own <leader>p* maps above
                focus_on_open = true,     -- jump into the float so you can scroll / nested-peek
                dismiss_on_move = false,  -- keep it open while you look; close with <leader>pc
                post_open_hook = nil,
            })
        end,
    },

}
