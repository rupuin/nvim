return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	branch = "main",
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = {
				"css",
				"html",
				"tsx",
				"lua",
				"bash",
				"ruby",
				"typescript",
				"solidity",
				"markdown",
				"python",
				"properties",
				"dart",
				"c",
			},
			sync_install = true,
			auto_install = false,
			highlight = {
				enable = true,
				disable = function(_, buf)
					local max_filesize = 50 * 1024
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					return ok and stats and stats.size > max_filesize
				end,
			},
			indent = { enable = true },
		})
	end,
}
