return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			auto_integrations = true,
			integrations = {
				fzf = true,
			},
		})

		vim.cmd.colorscheme("catppuccin-macchiato")
	end,
}
