return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	config = function()
		require("persistence").setup({
			dir = vim.fn.stdpath("state") .. "/sessions/",
			need = 1,
			branch = true,
		})

		-- Close plugin windows/buffers before saving so they never end up in sessions.
		-- persistence.nvim has no built-in exclude option; PersistenceSavePre is the documented approach.
		local excluded_fts = { "oil", "Outline", "OutlineHelp", "aerial" }
		local excluded_bts = { "terminal" }

		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistenceSavePre",
			callback = function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_valid(buf) then
						local dominated = vim.tbl_contains(excluded_fts, vim.bo[buf].filetype)
							or vim.tbl_contains(excluded_bts, vim.bo[buf].buftype)
						if dominated then
							vim.api.nvim_buf_delete(buf, { force = true })
						end
					end
				end
			end,
		})
	end,
	keys = {
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "Restore Session",
		},
		{
			"<leader>qS",
			function()
				require("persistence").select()
			end,
			desc = "Select Session",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "Restore Last Session",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "Don't Save Current Session",
		},
	},
}
