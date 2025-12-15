return {
	"akinsho/bufferline.nvim",
	dependencies = "nvim-tree/nvim-web-devicons",
	opts = {
		options = {
			show_buffer_close_icons = false,
			show_close_icon = false,
			color_icons = true,
			separator_style = "thin",
			diagnostics = "nvim_lsp",
			max_name_length = 30,
		},
	},
	config = function(_, opts)
		require("bufferline").setup(opts)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "help",
			callback = function()
				vim.bo.buflisted = true
			end,
		})
		local keymap = vim.keymap.set

		keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
		keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
	end,
}
