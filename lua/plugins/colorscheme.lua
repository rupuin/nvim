-- Highlight override helper (used by ColorScheme autocmd below)
local function apply_highlight_overrides()
	local colors_name = vim.g.colors_name
	if not colors_name then
		return
	end

	local function update(name, spec)
		vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", spec, { update = true }))
	end

	update("Cursor", { nocombine = true })
	update("lCursor", { nocombine = true })
	update("CursorIM", { nocombine = true })
	update("TermCursor", { nocombine = true })

	if colors_name == "gruvbox-material" and vim.o.background == "light" then
		update("Visual", { bg = "#dbca8f", nocombine = true })
		update("VisualNOS", { bg = "#dbca8f", nocombine = true })
		return
	end

	update("Visual", { nocombine = true })
	update("VisualNOS", { nocombine = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("user_highlight_overrides", { clear = true }),
	callback = apply_highlight_overrides,
})

-- vim.schedule(apply_highlight_overrides)

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
					bufferline = true,
					cmp = true,
					gitsigns = true,
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
				vim.g.gruvbox_material_foreground = "original"
				vim.g.gruvbox_material_visual = "grey background"
				vim.o.background = "light"
				vim.cmd.colorscheme("gruvbox-material")
			end,
		},
	},
}
