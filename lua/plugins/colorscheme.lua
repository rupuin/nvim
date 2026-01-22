return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	init = function()
		vim.cmd.colorscheme("catppuccin-macchiato")
	end,
	config = function()
		require("catppuccin").setup({
			auto_integrations = true,
		})
	end,
}
