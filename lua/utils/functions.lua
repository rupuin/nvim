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
	if current_file == "" then
		vim.notify("Current buffer has no file", vim.log.levels.WARN)
		return
	end

	if vim.fn.executable("rg") == 0 then
		vim.notify("go_to_test requires rg", vim.log.levels.ERROR)
		return
	end

	local test_markers = { "test", "spec", "tests", "t" }
	local prefix_test_markers = { "test", "spec", "tests" }
	local separators = { ".", "_", "-" }
	local test_dirs = {
		["__tests__"] = true,
		["spec"] = true,
		["test"] = true,
		["tests"] = true,
	}
	local ignored_path_parts = vim.tbl_extend("force", {
		["."] = true,
		["app"] = true,
		["integration"] = true,
		["lib"] = true,
		["src"] = true,
		["unit"] = true,
	}, test_dirs)
	local ignored_extensions = {
		["css"] = true,
		["gif"] = true,
		["jpeg"] = true,
		["jpg"] = true,
		["json"] = true,
		["less"] = true,
		["lock"] = true,
		["map"] = true,
		["md"] = true,
		["png"] = true,
		["sass"] = true,
		["scss"] = true,
		["snap"] = true,
		["svg"] = true,
		["webp"] = true,
		["yaml"] = true,
		["yml"] = true,
	}
	local js_ts_extensions = {
		js = true,
		jsx = true,
		ts = true,
		tsx = true,
	}

	local function basename(path)
		return path:match("([^/]+)$") or path
	end

	local function dirname(path)
		return path:match("^(.*)/[^/]+$") or "."
	end

	local function split_ext(name)
		local stem, ext = name:match("^(.*)%.([^%.]+)$")
		if not stem or stem == "" then
			return name, ""
		end
		return stem, ext
	end

	local function lua_pattern_escape(value)
		return value:gsub("([^%w])", "%%%1")
	end

	local function glob_escape(value)
		return value:gsub("([%[%]{}*?\\])", "\\%1")
	end

	local function parse_test_filename(name)
		local stem, ext = split_ext(name)

		for _, marker in ipairs(test_markers) do
			for _, sep in ipairs(separators) do
				if marker ~= "t" or sep == "." then
					local base = stem:match("^(.+)" .. lua_pattern_escape(sep) .. marker .. "$")
					if base then
						return { base = base, ext = ext }
					end
				end
			end
		end

		for _, marker in ipairs(prefix_test_markers) do
			for _, sep in ipairs(separators) do
				local base = stem:match("^" .. marker .. lua_pattern_escape(sep) .. "(.+)$")
				if base then
					return { base = base, ext = ext }
				end
			end
		end

		return nil
	end

	local function path_has_test_dir(path)
		for part in path:gmatch("[^/]+") do
			if test_dirs[part] then
				return true
			end
		end
		return false
	end

	local function is_test_file(path)
		return path_has_test_dir(path) or parse_test_filename(basename(path)) ~= nil
	end

	local function extension_candidates(ext, include_star)
		local result = {}
		local seen = {}
		local function add(candidate)
			if candidate ~= "" and not seen[candidate] then
				seen[candidate] = true
				table.insert(result, candidate)
			end
		end

		add(ext)
		if js_ts_extensions[ext] then
			for _, candidate in ipairs({ "tsx", "ts", "jsx", "js" }) do
				add(candidate)
			end
		end
		if include_star then
			add("*")
		end

		return result
	end

	local function extension_glob(ext)
		if ext == "*" then
			return ".*"
		end
		return "." .. glob_escape(ext)
	end

	local function add_glob(globs, seen, glob)
		if not seen[glob] then
			seen[glob] = true
			table.insert(globs, glob)
		end
	end

	local function test_globs(base, ext)
		local globs = {}
		local seen = {}
		local escaped_base = glob_escape(base)

		for _, candidate_ext in ipairs(extension_candidates(ext, true)) do
			local ext_glob = extension_glob(candidate_ext)
			for _, marker in ipairs(test_markers) do
				for _, sep in ipairs(separators) do
					if marker ~= "t" or sep == "." then
						add_glob(globs, seen, "**/" .. escaped_base .. glob_escape(sep) .. marker .. ext_glob)
					end
				end
			end
			for _, marker in ipairs(prefix_test_markers) do
				for _, sep in ipairs(separators) do
					add_glob(globs, seen, "**/" .. marker .. glob_escape(sep) .. escaped_base .. ext_glob)
				end
			end
		end

		for _, candidate_ext in ipairs(extension_candidates(ext, false)) do
			add_glob(globs, seen, "**/" .. escaped_base .. extension_glob(candidate_ext))
		end

		return globs
	end

	local function source_globs(base, ext)
		local globs = {}
		local seen = {}
		local escaped_base = glob_escape(base)

		for _, candidate_ext in ipairs(extension_candidates(ext, true)) do
			add_glob(globs, seen, "**/" .. escaped_base .. extension_glob(candidate_ext))
		end

		return globs
	end

	local function meaningful_path_parts(path)
		local parts = {}
		for part in path:gmatch("[^/]+") do
			local normalized = part:lower()
			if not ignored_path_parts[normalized] then
				table.insert(parts, normalized)
			end
		end
		return parts
	end

	local function shared_segments(left, right)
		local counts = {}
		local total = 0
		for _, part in ipairs(left) do
			counts[part] = (counts[part] or 0) + 1
		end
		for _, part in ipairs(right) do
			if counts[part] and counts[part] > 0 then
				counts[part] = counts[part] - 1
				total = total + 1
			end
		end
		return total
	end

	local function common_prefix(left, right)
		local total = 0
		while left[total + 1] and left[total + 1] == right[total + 1] do
			total = total + 1
		end
		return total
	end

	local function common_suffix(left, right)
		local total = 0
		local left_index = #left
		local right_index = #right
		while left_index > 0 and right_index > 0 and left[left_index] == right[right_index] do
			total = total + 1
			left_index = left_index - 1
			right_index = right_index - 1
		end
		return total
	end

	local function same_extension_family(left, right)
		return js_ts_extensions[left] and js_ts_extensions[right]
	end

	local root = vim.fs and vim.fs.root and vim.fs.root(current_file, { ".git" })
	if not root and vim.fs and vim.fs.find then
		local git_dir = vim.fs.find(".git", { upward = true, path = vim.fn.fnamemodify(current_file, ":p:h") })[1]
		root = git_dir and vim.fn.fnamemodify(git_dir, ":h")
	end
	root = root or vim.fn.getcwd()
	root = root:gsub("/$", "")

	local normalized_current_file = current_file:gsub("\\", "/")
	local normalized_root = root:gsub("\\", "/")
	local current_rel = normalized_current_file
	if normalized_current_file:sub(1, #normalized_root + 1) == normalized_root .. "/" then
		current_rel = normalized_current_file:sub(#normalized_root + 2)
	end

	local filename = basename(current_rel)
	local stem, ext = split_ext(filename)
	local test_info = parse_test_filename(filename)
	local current_is_test = test_info ~= nil or path_has_test_dir(current_rel)
	local target_base = test_info and test_info.base or stem
	local target_ext = test_info and test_info.ext or ext
	local globs = current_is_test and source_globs(target_base, target_ext) or test_globs(target_base, target_ext)
	local args = { "rg", "--files" }

	for _, glob in ipairs(globs) do
		table.insert(args, "--glob")
		table.insert(args, glob)
	end
	for _, glob in ipairs({ "!.git/**", "!node_modules/**", "!vendor/**", "!dist/**", "!build/**", "!coverage/**" }) do
		table.insert(args, "--glob")
		table.insert(args, glob)
	end
	table.insert(args, root)

	local output = vim.fn.systemlist(args)
	local candidates_by_path = {}
	local candidates = {}
	for _, candidate in ipairs(output) do
		local rel = candidate:gsub("\\", "/")
		if rel:sub(1, #normalized_root + 1) == normalized_root .. "/" then
			rel = rel:sub(#normalized_root + 2)
		end
		local _, candidate_ext = split_ext(basename(rel))
		if rel ~= "" and rel ~= current_rel and not ignored_extensions[candidate_ext] and not candidates_by_path[rel] then
			local candidate_is_test = is_test_file(rel)
			if candidate_is_test ~= current_is_test then
				candidates_by_path[rel] = true
				table.insert(candidates, rel)
			end
		end
	end

	if #candidates == 0 then
		local target_kind = current_is_test and "source file" or "test file"
		vim.notify(("No %s found for %s"):format(target_kind, filename), vim.log.levels.WARN)
		return
	end

	local current_parts = meaningful_path_parts(dirname(current_rel))
	local scored = vim.tbl_map(function(candidate)
		local candidate_parts = meaningful_path_parts(dirname(candidate))
		local _, candidate_ext = split_ext(basename(candidate))
		local score = 0

		if candidate_ext == target_ext then
			score = score + 20
		elseif same_extension_family(candidate_ext, target_ext) then
			score = score + 10
		end

		score = score + shared_segments(current_parts, candidate_parts) * 6
		score = score + common_suffix(current_parts, candidate_parts) * 10
		score = score + common_prefix(current_parts, candidate_parts) * 3
		score = score - math.abs(#current_parts - #candidate_parts)

		if not current_is_test and path_has_test_dir(candidate) then
			score = score + 8
		elseif current_is_test and not path_has_test_dir(candidate) then
			score = score + 8
		end

		return { path = candidate, score = score }
	end, candidates)

	table.sort(scored, function(left, right)
		if left.score == right.score then
			return left.path < right.path
		end
		return left.score > right.score
	end)

	local function edit_candidate(candidate)
		vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. candidate))
	end

	if #scored == 1 or scored[1].score - scored[2].score >= 10 then
		edit_candidate(scored[1].path)
		return
	end

	local choices = vim.tbl_map(function(candidate)
		return candidate.path
	end, scored)
	vim.ui.select(choices, { prompt = "Select test/source file" }, function(choice)
		if choice then
			edit_candidate(choice)
		end
	end)
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
