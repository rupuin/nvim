return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		local servers = {
			lua_ls = {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							library = {
								vim.fn.expand("$HOME/.local/share/nvim/lazy"),
								vim.env.VIMRUNTIME,
							},

							checkThirdParty = false,
						},
						telemetry = { enable = false },
					},
				},
			},
			gopls = {},
			vtsls = {},
			biome = {},
			basedpyright = {
				before_init = function(_, config)
					local root = config.root_dir
					if not root then
						return
					end

					local python = root .. "/.venv/bin/python"
					if vim.fn.executable(python) == 1 then
						config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
							python = { pythonPath = python },
						})
					end
				end,
				settings = {
					basedpyright = {
						analysis = {
							diagnosticMode = "workspace",
						},
					},
				},
			},
			ruby_ls = {
				cmd = { "mise", "exec", "--", "ruby-lsp" },
				filetypes = { "ruby" },
				init_options = {
					formatter = "rubocop",
					formatterPath = "bundle",
					formatterArgs = { "exec", "rubocop" },
				},
			},
			solidity_ls = {
				cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
			},
			yamlls = {
				filetypes = { "yaml", "yml" },
				settings = {
					yaml = {
						completion = true,
						keyOrdering = false,
						format = { enable = true },
						validate = true,
						hover = true,
						schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
					},
				},
				redhat = {
					telemetry = { enabled = false },
				},
			},
		}

		for name, opts in pairs(servers) do
			opts.capabilities = capabilities
			vim.lsp.config(name, opts)
			vim.lsp.enable(name)
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
			callback = function(event)
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				local bufnr = event.buf
				local fzf = require("fzf-lua")

				if client and client.server_capabilities.documentSymbolProvider then
					require("nvim-navic").attach(client, bufnr)
				end

				local keymap = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, {
						buffer = event.buf,
						silent = true,
						desc = desc,
					})
				end

				local only_symbol_kinds = function(kinds)
					local allow = {}
					for _, kind in ipairs(kinds) do
						allow[kind] = true
					end

					return function(item)
						local kind = item.kind or (item.text and item.text:match("%[(.-)%]"))
						return kind and allow[kind] or false
					end
				end

				local symbol_picker_opts = {
					child_prefix = false,
					parent_postfix = " > ",
					symbol_style = 1,
				}

				keymap("gd", function()
					fzf.lsp_definitions()
				end, "Go to definition")
				keymap("gD", function()
					fzf.lsp_declarations()
				end, "Go to declarations")
				keymap("gr", function()
					fzf.lsp_references()
				end, "Go to references")
				keymap("gi", function()
					fzf.lsp_implementations()
				end, "Go to implementations")
				keymap("gy", function()
					fzf.lsp_typedefs()
				end, "Go to type definitions")
				keymap("gO", function()
					fzf.lsp_document_symbols(symbol_picker_opts)
				end, "Document symbols")
				keymap("<leader>sf", function()
					fzf.lsp_document_symbols(vim.tbl_deep_extend("force", symbol_picker_opts, {
						regex_filter = only_symbol_kinds({ "Function", "Method" }),
					}))
				end, "Symbols: functions")
				keymap("<leader>sv", function()
					fzf.lsp_document_symbols(vim.tbl_deep_extend("force", symbol_picker_opts, {
						regex_filter = only_symbol_kinds({ "Variable", "Field", "Property", "Object" }),
					}))
				end, "Symbols: variables")
				keymap("<leader>st", function()
					fzf.lsp_document_symbols(vim.tbl_deep_extend("force", symbol_picker_opts, {
						regex_filter = only_symbol_kinds({ "Class", "Struct", "Interface", "Enum", "TypeParameter" }),
					}))
				end, "Symbols: types")
				keymap("K", function()
					vim.lsp.buf.hover({
						focusable = true,
						max_width = 120,
						close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "BufLeave" },
					})
				end, "Hover documentation")

				keymap("<leader>f", function()
					require("conform").format({ async = true, lsp_fallback = false })
				end, "Format buffer")
			end,
		})

		vim.diagnostic.config({
			virtual_text = true,
			signs = false,
			underline = false,
			update_in_insert = false,
			severity_sort = false,
		})
	end,
}
