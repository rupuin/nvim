return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		local function safe_root(markers)
			local found = vim.fs.find(markers, { upward = true })[1]
			return found and vim.fs.dirname(found) or (vim.uv and vim.uv.cwd() or vim.loop.cwd())
		end

		local servers = {
			ruby_ls = {
				cmd = { "mise", "exec", "--", "ruby-lsp" },
				filetypes = { "ruby" },
				root_dir = safe_root({ "Gemfile", ".git", ".ruby-version", "Rakefile", ".tool-versions" }),
				init_options = {
					formatter = "rubocop",
					formatterPath = "bundle",
					formatterArgs = { "exec", "rubocop" },
				},
			},
			lua_ls = {
				root_dir = safe_root({
					".luarc.json",
					".luarc.jsonc",
					".luacheckrc",
					".stylua.toml",
					"stylua.toml",
					"selene.toml",
					"selene.yml",
					".git",
				}),
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
						telemetry = { enable = false },
					},
				},
			},
			gopls = {},
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

				keymap("gd", function() require("fzf-lua").lsp_definitions() end, "Go to definition")
				keymap("gD", function() require("fzf-lua").lsp_declarations() end, "Go to declarations")
				keymap("gr", function() require("fzf-lua").lsp_references() end, "Go to references")
				keymap("gi", function() require("fzf-lua").lsp_implementations() end, "Go to implementations")
				keymap("gy", function() require("fzf-lua").lsp_typedefs() end, "Go to type definitions")
				keymap("K", function()
					vim.lsp.buf.hover({
						focusable = true,
						border = "rounded",
						max_width = 120,
						close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "BufLeave" },
					})
				end, "Hover documentation")

				local util_fns = require("utils.functions")

				keymap("<leader>K", function()
					vim.lsp.buf.hover({
						focusable = true,
						border = "rounded",
						max_width = 120,
					})
					vim.defer_fn(function()
						util_fns.focus_hover_window()
					end, 10)
				end, "Hover (focus window to scroll)")
				keymap("<leader>f", vim.lsp.buf.format, "Format buffer")
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
