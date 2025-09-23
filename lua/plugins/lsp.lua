return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", config = true },
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- Configure Ruby LSP with mise
		vim.lsp.config("ruby_ls", {
			cmd = { "mise", "exec", "--", "ruby-lsp" },
			filetypes = { "ruby" },
			root_dir = vim.fs.dirname(
				vim.fs.find({ "Gemfile", ".git", ".ruby-version", "Rakefile", ".tool-versions" }, { upward = true })[1]
			),
			init_options = {
				formatter = "rubocop",
				formatterPath = "bundle",
				formatterArgs = { "exec", "rubocop" },
			},
		})
		vim.lsp.enable("ruby_ls")

		-- Configure Lua LSP
		vim.lsp.config("lua_ls", {
			root_dir = vim.fs.dirname(vim.fs.find({
				".luarc.json",
				".luarc.jsonc",
				".luacheckrc",
				".stylua.toml",
				"stylua.toml",
				"selene.toml",
				"selene.yml",
				".git",
			}, { upward = true })[1]),
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
		})
		vim.lsp.enable("lua_ls")

		-- Configure Go LSP
		vim.lsp.config("gopls", {})
		vim.lsp.enable("gopls")

		-- Configure YAML LSP
		vim.lsp.config("yamlls", {
			filetypes = { "yaml", "yml" },
			settings = {
				yaml = {
					completion = true,
					keyOrdering = false,
					format = { enable = true },
					validate = true,
					hover = true,
					schemaStore = {
						enable = true,
						url = "https://www.schemastore.org/api/json/catalog.json",
					},
				},
			},
		})
		vim.lsp.enable("yamlls")

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
			end,
		})

		-- close floating hover win after cursor move
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = vim.api.nvim_create_augroup("CloseLspFloats", { clear = true }),
			callback = function()
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_config(win).relative ~= "" then
						vim.api.nvim_win_close(win, false)
					end
				end
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
