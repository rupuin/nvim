return {
	{
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
		end,
	},
	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
	},
	{
		"f-person/auto-dark-mode.nvim",
		opts = {
			set_dark_mode = function()
				vim.o.background = "dark"
				vim.cmd.colorscheme("catppuccin-macchiato")
			end,
			set_light_mode = function()
				vim.g.gruvbox_material_background = "hard"
				vim.g.gruvbox_material_foreground = "material"
				vim.o.background = "light"
				vim.cmd.colorscheme("gruvbox-material")
			end,
		},
	},
}
