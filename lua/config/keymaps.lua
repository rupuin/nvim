local keymap = vim.keymap.set

keymap("n", "<Esc>", ":nohlsearch<CR>", { noremap = true, silent = true, desc = "Clear search highlight" })
keymap("n", "<leader>bd", ":bdelete<CR>", { noremap = true, silent = true, desc = "Delete current buffer" })
keymap("n", "<leader>bo", ":%bd|e#|bd#<CR>", { noremap = true, silent = true, desc = "Delete all other buffers" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Window down" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Window up" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Window right" })
keymap("n", "<C-h>", "<C-w>h", { desc = "Window left" })
keymap("n", "<leader>wh", "<C-w>s", { desc = "Window split horizontally" })
keymap("n", "<leader>wv", "<C-w>v", { desc = "Window split verically" })
keymap("n", "<leader>wq", "<cmd>:q<cr>", { desc = "Close window" })

-- keymaps for funcs
keymap("n", "<leader>rs", function() require("utils.functions").go_to_test() end, { noremap = true, silent = true, desc = "Go to test" })
keymap("n", "<leader>ry", function() require("utils.functions").copy_file_path() end, { noremap = true, silent = true, desc = "Copy file path" })
keymap("n", "<leader>fo", function() require("utils.functions").find_code_owners() end, { noremap = true, silent = true, desc = "Find code owners" })
keymap(
	"n",
	"<leader>ro",
	function() require("utils.functions").codeowners_to_clipboard() end,
	{ noremap = true, silent = true, desc = "Copy code owners to clipboard" }
)

keymap(
	"n",
	"<leader>gp",
	function() require("utils.functions").find_pr_of_current_line() end,
	{ noremap = true, silent = true, desc = "Find PR of current line" }
)
