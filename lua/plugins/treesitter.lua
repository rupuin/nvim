return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		local langs = {
			go = { ft = { "go" } },
			lua = { ft = { "lua" } },
			bash = { ft = { "sh" } },
			ruby = { ft = { "ruby" } },
			python = { ft = { "python" } },
			markdown = { ft = { "markdown" } },
			markdown_inline = {},
			html = { ft = { "html" } },
			css = { ft = { "css" } },
			typescript = { ft = { "typescript" } },
			tsx = { ft = { "typescriptreact" } },
			dart = { ft = { "dart" } },
			c = { ft = { "c" } },
			properties = { ft = { "properties" } },
			solidity = { ft = { "solidity" } },
		}

		local parsers = {}
		local patterns = {}

		for parser, spec in pairs(langs) do
			table.insert(parsers, parser)

			for _, ft in ipairs(spec.ft or {}) do
				table.insert(patterns, ft)
			end
		end

		require("nvim-treesitter").setup()
		require("nvim-treesitter").install(parsers)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = patterns,
			callback = function(args)
				pcall(vim.treesitter.start, args.buf)
			end,
		})
	end,
}
