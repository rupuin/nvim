local M = {}

function M.focus_hover_window()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local cfg = vim.api.nvim_win_get_config(win)
		if cfg.relative ~= "" then
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[buf].filetype
			local name = vim.api.nvim_buf_get_name(buf)
			if ft == "markdown" or name:match("lsp_hover") then
				vim.api.nvim_set_current_win(win)
				return true
			end
		end
	end
	return false
end

function M.find_pr_of_current_line()
	local file_name = vim.api.nvim_buf_get_name(0)
	local line_number = vim.api.nvim_win_get_cursor(0)[1]

	local pr_command = "git log -1 $(git blame -L "
		.. line_number
		.. ","
		.. line_number
		.. " "
		.. file_name
		.. " | cut -d ' ' -f 1 | sed 's/^\\^//') |  grep -o '#[0-9]\\+' | sed 's/#//'"
	local pr = vim.fn.system(pr_command):gsub("%s+", "")

	if pr == "" then
		print("PR not found, this was probably merged straight to master")
		return
	end

	local base_command = "git remote -v | grep '(fetch)' | sed 's/^.*@//;s/ .*$//;s/:/\\//;s/\\.git//'"
	local base = vim.fn.system(base_command):gsub("%s+", "")

	local url = "https://" .. base .. "/pull/" .. pr
	vim.fn.system("open '" .. url .. "'")
end

function M.find_code_owners()
	local full_filename = vim.fn.expand("%:p") -- Get absolute path of the current file

	local relative_filename = full_filename:match(".*/core/(.*)")
	local package_name = full_filename:match("packages/([^/]+)/")

	if not relative_filename then
		relative_filename = full_filename
	end

	local codeowners_path = "CODEOWNERS"
	local file = io.open(codeowners_path, "r")
	if not file then
		vim.notify("Couldn't open CODEOWNERS file.", vim.log.levels.ERROR)
		return
	end

	local best_match = nil
	local best_match_length = 0

	for line in file:lines() do
		local path_pattern, owners_str = line:match("^(%S+)%s+(.+)$")
		if path_pattern and full_filename:find(path_pattern) then
			if #path_pattern > best_match_length then
				best_match = vim.split(owners_str, "%s+")
				best_match_length = #path_pattern
			end
		end
	end
	file:close()

	if not best_match or #best_match == 0 then
		vim.notify("No owners found for this file.", vim.log.levels.WARN)
	else
		local message = "File: "
			.. relative_filename
			.. "\n"
			.. "Package: "
			.. package_name
			.. "\n\n"
			.. table.concat(best_match, "\n")
		vim.notify(message, vim.log.levels.INFO)
	end
end

function M.codeowners_to_clipboard()
	local full_filename = vim.fn.expand("%:p") -- Get absolute path of the current file

	local relative_filename = full_filename:match(".*/core/(.*)")

	if not relative_filename then
		relative_filename = full_filename
	end

	local codeowners_path = "CODEOWNERS"
	local file = io.open(codeowners_path, "r")
	if not file then
		vim.notify("Couldn't open CODEOWNERS file.", vim.log.levels.ERROR)
		return
	end

	local owners = {}
	for line in file:lines() do
		local path_pattern, owners_str = line:match("^(%S+)%s+(.+)$")
		if path_pattern and full_filename:find(path_pattern) then
			owners = vim.split(owners_str, "%s+")
			break
		end
	end
	file:close()

	if #owners == 0 then
		vim.notify("No owners found for this file.", vim.log.levels.WARN)
	else
		local clipboard_content = table.concat(owners, "\n")
		vim.fn.setreg("+", clipboard_content)
		vim.notify("Code owners copied to clipboard.", vim.log.levels.INFO)
	end
end

function M.go_to_test()
	local current_file = vim.fn.expand("%:p")
	local filetype = vim.bo.filetype
	local target_file

	local lang_map = {
		ruby = {
			test_dir = "/spec/",
			src_dir = "/app/",
			test_postfix = "_spec.rb",
			src_postfix = ".rb",
		},
		solidity = {
			test_dir = "/test/",
			src_dir = "/src/",
			test_postfix = ".t.sol",
			src_postfix = ".sol",
		},
		go = {
			test_dir = nil,
			src_dir = nil,
			test_postfix = "_test.go",
			src_postfix = ".go",
		},
	}

	local lang = lang_map[filetype]
	if not lang then
		vim.notify(("Unsupported file type: %s"):format(filetype))
		return
	end

	if filetype == "go" then
		if current_file:match("_test%.go$") then
			target_file = current_file:gsub("_test%.go$", ".go")
		else
			target_file = current_file:gsub("%.go$", "_test.go")
		end
	else
		if current_file:match(lang.test_dir) then
			target_file = current_file:gsub(lang.test_dir, lang.src_dir):gsub(lang.test_postfix, lang.src_postfix)
		else
			target_file = current_file:gsub(lang.src_dir, lang.test_dir):gsub(lang.src_postfix, lang.test_postfix)
		end
	end

	if vim.fn.filereadable(target_file) == 0 then
		vim.notify(("Can't find file: %s"):format(target_file))
	end

	vim.cmd("edit " .. target_file)
end

function M.copy_file_path()
	local current_file = vim.fn.expand("%:p")
	local current_file_name = vim.fn.expand("%:t")
	local modify = vim.fn.fnamemodify

	local vals = {
		["BASENAME"] = modify(current_file_name, ":r"),
		["EXTENSION"] = modify(current_file_name, ":e"),
		["FILENAME"] = current_file_name,
		["PATH (CWD)"] = modify(current_file, ":."),
		["PATH (HOME)"] = modify(current_file, ":~"),
		["PATH"] = current_file,
		["URI"] = vim.uri_from_fname(current_file),
	}

	local options = vim.tbl_filter(function(val)
		return vals[val] ~= ""
	end, vim.tbl_keys(vals))

	if vim.tbl_isempty(options) then
		vim.notify("No values to copy", vim.log.levels.WARN)
		return
	end

	table.sort(options)

	vim.ui.select(options, {
		format_item = function(item)
			return ("%s: %s"):format(item, vals[item])
		end,
	}, function(choice)
		local result = vals[choice]
		if result then
			vim.notify(("Copied: `%s`"):format(result))
			vim.fn.setreg("+", result)
		end
	end)
end

return M
