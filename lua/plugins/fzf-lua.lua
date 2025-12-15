return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = function(_, opts)
		local fzf = require("fzf-lua")
		local config = fzf.config

		config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
		config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
		config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
		config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
		config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
		config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"
		config.defaults.keymap.builtin["<c-l>"] = "select_split"

		opts.files = opts.files or {}
		-- removes the path from picker search window
		opts.files.cwd_prompt = false
		return opts
	end,
	config = function(_, opts)
		local fzf = require("fzf-lua")
		fzf.setup(opts)
		-- fzf.register_ui_select()
	end,
	keys = {
		{ "<leader><leader>", "<cmd>FzfLua files<cr>", desc = "Find Files" },
		{ "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
		{ "<leader>,", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
		{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
		{ "<leader>sm", "<cmd>FzfLua marks<cr>", desc = "Marks" },
	},
}
