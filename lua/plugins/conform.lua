return {
	"stevearc/conform.nvim",
	opts = {
		formatters = {
			rubocop = {
				command = "mise",
				args = {
					"exec",
					"--",
					"bundle",
					"exec",
					"rubocop",
					"--autocorrect",
					"--stdin",
					"$FILENAME",
					"--stderr",
					"--format",
					"quiet",
				},
				stdin = true,
			},
			biome = {
				command = "./node_modules/.bin/biome",
				require_cwd = true,
			},
		},
		formatters_by_ft = {
			lua = { "stylua" },
			ruby = { "rubocop" },
			go = { "goimports" },
			python = { "ruff_format" },
			typescript = { "biome" },
			yaml = { "prettierd" },
			yml = { "prettierd" },
			json = { "biome" },
		},
		format_on_save = { timeout_ms = 5000 },
	},
}
