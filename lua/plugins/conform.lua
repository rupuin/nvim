local biome_config_files = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }

local function biome_root(_, ctx)
	return vim.fs.root(ctx.dirname, biome_config_files)
end

local function has_biome_config(_, ctx)
	return biome_root(nil, ctx) ~= nil
end

local function biome_command(_, ctx)
	local root = biome_root(nil, ctx)
	if root then
		local local_biome = root .. "/node_modules/.bin/biome"
		if vim.fn.executable(local_biome) == 1 then
			return local_biome
		end
	end

	return "biome"
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
				command = biome_command,
				args = { "check", "--write", "--stdin-file-path", "$FILENAME" },
				stdin = true,
				cwd = biome_root,
				require_cwd = true,
				condition = has_biome_config,
			},
			biome_mason = {
				command = "biome",
				args = { "format", "--stdin-file-path", "$FILENAME" },
				stdin = true,
				condition = function(_, ctx)
					return not has_biome_config(nil, ctx)
				end,
			},
		},
		formatters_by_ft = {
			lua = { "stylua" },
			ruby = { "rubocop" },
			go = { "goimports" },
			python = { "ruff_format", "docformatter" },
			typescriptreact = { "biome_local", "biome_mason" },
			typescript = { "biome_local", "biome_mason" },
			javascript = { "biome_local", "biome_mason" },
			yaml = { "prettierd" },
			yml = { "prettierd" },
			json = { "biome_local", "biome_mason" },
			json5 = { "prettierd" },
		},
		format_on_save = { timeout_ms = 5000 },
	},
}
