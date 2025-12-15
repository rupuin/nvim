return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	config = function()
		require("persistence").setup({
			dir = vim.fn.stdpath("state") .. "/sessions/",
			need = 1,
			branch = true,
		})

		-- mark Oil buffers as unlisted before saving
		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistenceSavePre",
			callback = function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_valid(buf) then
						local name = vim.api.nvim_buf_get_name(buf)
						local ft = vim.bo[buf].filetype

						if ft == "oil" or name:match("^oil://") then
							vim.bo[buf].buflisted = false
						end
					end
				end
			end,
		})

		-- clean up restored Oil buffers after loading
		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistenceLoadPost",
			callback = function()
				vim.defer_fn(function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_valid(buf) then
							local name = vim.api.nvim_buf_get_name(buf)
							local ok, ft = pcall(function()
								return vim.bo[buf].filetype
							end)

							if (ok and ft == "oil") or name:match("^oil://") then
								vim.api.nvim_buf_delete(buf, { force = true })
							end
						end
					end
				end, 50)
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
