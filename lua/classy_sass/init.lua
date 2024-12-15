local M = {}

-- Default options
local default_opts = {
	indent_width = 2,
	silent = false, -- Option to control error message visibility
	auto_write = true, -- Option to control automatic buffer writing
}

-- Error handling utility functions
local function notify_error(msg, level)
	if not (M.opts and M.opts.silent) then
		vim.notify(msg, level or vim.log.levels.ERROR)
	end
end

local function safe_operation(operation, error_msg)
	-- Check that operation is actually a function
	if type(operation) ~= "function" then
		notify_error("Invalid operation passed to safe_operation")
		return nil
	end

	local ok, result = pcall(operation)
	if not ok then
		notify_error(error_msg .. ": " .. tostring(result))
		return nil
	end
	return result
end

--- Resolves the full selector path based on the current stack and a new selector
--- @param selector_stack table The stack of parent selectors
--- @param current_selector string The new selector to resolve
--- @return string|nil The resolved selector or nil if an error occurs
M.resolve_selector = function(selector_stack, current_selector)
	if type(selector_stack) ~= "table" then
		notify_error("Invalid selector_stack type: expected table")
		return nil
	end

	if type(current_selector) ~= "string" then
		notify_error("Invalid selector type: expected string")
		return nil
	end

	if current_selector:sub(1, 1) == "&" then
		local parent = selector_stack[#selector_stack]
		if not parent then
			notify_error("Parent selector reference '&' used without parent context")
			return current_selector:sub(2)
		end
		return parent .. current_selector:sub(2)
	elseif #selector_stack > 0 then
		return selector_stack[#selector_stack] .. " " .. current_selector
	end
	return current_selector
end

--- Validates if the buffer is valid and its filetype is supported
--- @param bufnr number The buffer number
--- @return boolean True if valid, false otherwise
local function validate_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		notify_error("Invalid buffer")
		return false
	end

	local ft = vim.bo[bufnr].filetype
	if ft ~= "scss" and ft ~= "sass" and ft ~= "css" then
		notify_error("Buffer filetype is not scss/sass/css")
		return false
	end

	return true
end

--- Process a single line of SCSS code
--- @param line string The line to process
--- @param line_num number The line number
--- @param selector_stack table The current selector stack
--- @param current_indent number The current indentation level
--- @param output_lines table The table of processed lines
--- @return boolean success Whether the line was processed successfully

local function process_line(line, line_num, selector_stack, current_indent, output_lines)
	local indent = line:match("^%s*") or ""
	local trimmed_line = line:match("^%s*(.*)") or ""

	if trimmed_line == "" then
		table.insert(output_lines, line)
		return true
	end

	-- Check if the previous line was a comment
	local prev_line = output_lines[#output_lines]
	local has_comment = prev_line and prev_line:match("^%s*// ") ~= nil

	if trimmed_line == "}" then
		-- Remove all selectors that are deeper than current indent
		while #selector_stack > current_indent do
			table.remove(selector_stack)
		end
	elseif trimmed_line:match("{%s*$") then
		local selector = trimmed_line:match("^([^{]+)")
		if not selector then
			notify_error(string.format("Invalid selector at line %d", line_num))
			return false
		end

		selector = selector:gsub("%s+$", "")
		local full_selector = M.resolve_selector(selector_stack, selector)

		if full_selector then
			table.insert(selector_stack, full_selector)
			-- Only add comment if:
			-- 1. There isn't already a comment
			-- 2. Current indent is not 0 (not top-level)
			if
				current_indent > 0 and (not has_comment or not prev_line:match("// " .. vim.pesc(full_selector) .. "$"))
			then
				table.insert(output_lines, indent .. "// " .. full_selector)
			end
		end
	end

	table.insert(output_lines, line)
	return true
end

--- Main function to add SCSS comments
M.add_scss_comments = function()
	local bufnr = vim.api.nvim_get_current_buf()

	-- Validate buffer
	if not validate_buffer(bufnr) then
		return
	end

	-- Get buffer lines safely
	local lines = safe_operation(function()
		return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	end, "Failed to read buffer contents")

	if not lines then
		return
	end

	local selector_stack = {}
	local output_lines = {}
	local indent_width = M.opts.indent_width

	-- Process lines
	for line_num, line in ipairs(lines) do
		local current_indent = math.floor((line:match("^%s*") or ""):len() / indent_width)

		local ok, result = pcall(function()
			return process_line(line, line_num, selector_stack, current_indent, output_lines)
		end)

		if not ok or result == false then
			notify_error(string.format("Error processing line %d: %s", line_num, ok and "Invalid selector" or result))
			return
		end
	end

	-- Safely update buffer contents
	local ok = safe_operation(function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output_lines)
		if M.opts.auto_write then
			vim.cmd("write")
		end
	end, "Failed to update buffer contents")
end

--- Plugin setup function with error handling
--- @param user_opts table|nil User options to customize plugin behavior
M.setup = function(user_opts)
	-- Validate user options
	if user_opts ~= nil and type(user_opts) ~= "table" then
		error("Setup options must be a table")
		return
	end

	-- Validate specific options
	if user_opts and user_opts.indent_width then
		if type(user_opts.indent_width) ~= "number" then
			error("indent_width must be a number")
			return
		end
		if user_opts.indent_width < 1 then
			error("indent_width must be positive")
			return
		end
	end

	-- Merge user options with default options
	M.opts = vim.tbl_deep_extend("force", {}, default_opts, user_opts or {})

	-- Safely create user command
	safe_operation(function()
		vim.api.nvim_create_user_command("AddSCSSComments", M.add_scss_comments, {})
	end, "Failed to create user command")

	-- Set default keybinding if it hasn't been mapped already
	if vim.fn.mapcheck("<leader>ac", "n") == "" then
		safe_operation(function()
			vim.keymap.set("n", "<leader>ac", ":AddSCSSComments<CR>", {
				desc = "Add SCSS Comments",
				silent = true,
			})
		end, "Failed to set up keybinding")
	end
end

return M
