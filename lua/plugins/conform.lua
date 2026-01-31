local function has_biome_config(ctx)
	return vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.dirname, upward = true })[1] ~= nil
end

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
			biome_local = {
				command = "./node_modules/.bin/biome",
				require_cwd = true,
				condition = has_biome_config,
			},
			biome_mason = {
				command = "biome",
				args = { "format", "--stdin-file-path", "$FILENAME" },
				stdin = true,
				condition = function(ctx)
					return not has_biome_config(ctx)
				end,
			},
		},
		formatters_by_ft = {
			lua = { "stylua" },
			ruby = { "rubocop" },
			go = { "goimports" },
			python = { "ruff_format" },
			typescript = { "biome_local", "biome_mason" },
			yaml = { "prettierd" },
			yml = { "prettierd" },
			json = { "biome_local", "biome_mason" },
		},
		format_on_save = { timeout_ms = 5000 },
	},
}
