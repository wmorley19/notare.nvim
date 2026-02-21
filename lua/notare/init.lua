local M = {}

-- Get the plugin directory
local function get_plugin_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	-- Remove /lua/notare/init.lua to get plugin root
	return vim.fn.fnamemodify(source, ":h:h:h")
end

-- Detect OS and architecture
local function detect_platform()
	local os = vim.loop.os_uname().sysname:lower()
	local arch = vim.loop.os_uname().machine

	if os:match("darwin") then
		os = "darwin"
	elseif os:match("linux") then
		os = "linux"
	elseif os:match("windows") then
		os = "windows"
	end

	if arch == "x86_64" or arch == "amd64" then
		arch = "amd64"
	elseif arch == "aarch64" or arch == "arm64" then
		arch = "arm64"
	end

	return os, arch
end

-- Find the CLI binary
local function find_cli_binary()
	local plugin_dir = get_plugin_dir()
	local bin_dir = plugin_dir .. "/bin"
	local os, arch = detect_platform()

	-- Try platform-specific binary first
	local ext = os == "windows" and ".exe" or ""
	local platform_binary = string.format("%s/notare-cli-%s-%s%s", bin_dir, os, arch, ext)

	if vim.fn.filereadable(platform_binary) == 1 then
		return platform_binary
	end

	-- Try generic binary
	local generic_binary = bin_dir .. "/notare-cli" .. ext
	if vim.fn.filereadable(generic_binary) == 1 then
		return generic_binary
	end

	-- Try to find in PATH
	local path_binary = vim.fn.exepath("notare-cli")
	if path_binary ~= "" then
		return path_binary
	end

	return nil
end

-- Configuration
M.config = {
	notare_cli_path = nil, -- Will be auto-detected
	notare_url = vim.env.NOTARE_URL or "",
	notare_username = vim.env.NOTARE_USERNAME or "",
	notare_api_token = vim.env.NOTARE_API_TOKEN or "",
	template_path = nil, -- Path to custom template file (optional)
	-- Set to true for Chalk / backends where page URLs should not use /wiki prefix
	notare_no_wiki = false,
}

function M.setup(opts)
	local env_provider = vim.env.NOTARE_PROVIDER or ""
	if env_provider:lower() == "chalk" then
		M.config.notare_no_wiki = true
	end
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	if M.config.notare_no_wiki then
		vim.env.NOTARE_PROVIDER = "chalk"
	end

	-- Auto-detect CLI binary if not specified
	if not M.config.notare_cli_path or M.config.notare_cli_path == "" then
		M.config.notare_cli_path = find_cli_binary()
	end

	-- Validate CLI binary exists
	if not M.config.notare_cli_path then
		vim.notify(
			"notare CLI binary not found. Please run the install script:\n"
				.. "cd "
				.. get_plugin_dir()
				.. " && go build -o ../../bin/notare-cli",
			vim.log.levels.ERROR
		)
		return
	end

	if vim.fn.filereadable(M.config.notare_cli_path) == 0 then
		vim.notify("notare CLI binary not found at: " .. M.config.notare_cli_path, vim.log.levels.ERROR)
		return
	end

	-- Set environment variables for the CLI
	vim.env.NOTARE_URL = M.config.notare_url
	vim.env.NOTARE_USERNAME = M.config.notare_username
	vim.env.NOTARE_API_TOKEN = M.config.notare_api_token
	if M.config.notare_no_wiki then
		vim.env.NOTARE_PROVIDER = "chalk"
	end

	-- Validate configuration
	if M.config.notare_url == "" or M.config.notare_api_token == "" then
		vim.notify(
			"Confluence credentials not configured. Please set:\n"
				.. "- notare_url\n"
				.. "- notare_api_token\n"
				.. "Or pass them in setup()",
			vim.log.levels.WARN
		)
	end

	-- Create user commands
	vim.api.nvim_create_user_command("NotarePush", function()
		require("notare.push").push_current_file()
	end, { desc = "Push current markdown file to Conflunce" })

	vim.api.nvim_create_user_command("NotarePull", function()
		require("notare.pull").pull_page()
	end, { desc = "Pull a Confluence page as markdown" })

	vim.api.nvim_create_user_command("NotareUpdate", function()
		require("notare.update").update_current_file()
	end, { desc = "Update existing Confluence page" })

	vim.api.nvim_create_user_command("NotareSpaces", function()
		require("notare.spaces").list_spaces()
	end, { desc = "Browse Confluence spaces" })

	vim.api.nvim_create_user_command("NotarePages", function()
		require("notare.pages").list_pages()
	end, { desc = "Browse Confluence pages" })

	vim.api.nvim_create_user_command("NotareNewDoc", function()
		require("notare.new").create_new_doc()
	end, { desc = "Create new document from template" })

	vim.api.nvim_create_user_command("NotareNewDocTemplate", function()
		require("notare.new").create_new_doc_with_template()
	end, { desc = "Create new document and select template" })

	vim.notify("notare.nvim loaded successfully!", vim.log.levels.INFO)
end

return M
