vim.opt.termguicolors = true
vim.opt.timeoutlen = 300
vim.o.cursorline = true
vim.o.laststatus = 3
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- fixes cursor visibily for light mode within tmux session
vim.opt.guicursor =
	"n-v-c-sm:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr-o:hor20-Cursor/lCursor,t:block-TermCursor"
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.filetype.add({
	pattern = {
		["%.env%..*"] = "properties",
		["%.env"] = "properties",
	},
})
