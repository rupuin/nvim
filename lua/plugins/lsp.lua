return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		local lspconfig = require("lspconfig")

		local servers = {
			ruby_lsp = {
				mason = false,
				cmd = { "mise", "exec", "--", "ruby-lsp" },
				filetypes = { "ruby" },
				root_dir = lspconfig.util.root_pattern("Gemfile", ".git"),
				init_options = {
					formatter = "rubocop",
					formatterPath = "bundle",
					formatterArgs = { "exec", "rubocop" },
				},
			},
			lua_ls = {
				root_dir = lspconfig.util.root_pattern(
					".luarc.json",
					".luarc.jsonc",
					".luacheckrc",
					".stylua.toml",
					"stylua.toml",
					"selene.toml",
					"selene.yml",
					".git"
				),
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
				mason = true,
				filetypes = { "yaml", "yml" },
				settings = {
					yaml = {
						completion = true,
						keyOrdering = false,
						format = {
							enable = true,
						},
						validate = true,
						hover = true,
						schemaStore = {
							enable = true,
							url = "https://www.schemastore.org/api/json/catalog.json",
						},
					},
				},
			},
		}

		local mason_servers = {}
		for server, config in pairs(servers) do
			if config.mason == false then
				lspconfig[server].setup(config)
			else
				table.insert(mason_servers, server)
			end
		end

		require("mason-lspconfig").setup({
			ensure_installed = mason_servers,
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),

			callback = function(event)
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				local bufnr = event.buf

				if client and client.server_capabilities.documentSymbolProvider then
					require("nvim-navic").attach(client, bufnr)
				end

				local fzf = require("fzf-lua")
				local keymap = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, {
						buffer = event.buf,
						silent = true,
						desc = desc,
					})
				end

				keymap("gd", fzf.lsp_definitions, "Go to definition")
				keymap("gD", fzf.lsp_declarations, "Go to declarations")
				keymap("gr", fzf.lsp_references, "Go to references")
				keymap("gi", fzf.lsp_implementations, "Go to implementations")
				keymap("gy", fzf.lsp_typedefs, "Go to type definitions")
				keymap("K", vim.lsp.buf.hover, "Hover documentation")
				keymap("<leader>f", vim.lsp.buf.format, "Format buffer")
				keymap("<leader>e", function()
					require("fzf-lua").diagnostics_document()
				end, "Document Diagnostics")
				keymap("<leader>E", function()
					require("fzf-lua").diagnostics_workspace()
				end, "Workspace Diagnostics")
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
