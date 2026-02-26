local M = {}

local health = vim.health or require("health")

M.check = function()
	health.start("notare.nvim")

	-- Check if plugin is loaded
	local ok, notare = pcall(require, "notare")
	if not ok then
		health.error("Failed to load notare.nvim")
		return
	end
	health.ok("Plugin loaded successfully")

	-- Check CLI binary
	local cli_path = notare.config.notare_cli_path
	if not cli_path or cli_path == "" then
		health.error("CLI binary path not configured")
		health.info("Run: cd <plugin-dir> go build -o ../../bin/notare-cli .")
		return
	end

	if vim.fn.filereadable(cli_path) == 0 then
		health.error("CLI binary not found at: " .. cli_path)
		health.info("Run: cd <plugin-dir> go build -o ../../bin/notare-cli .")
		return
	end

	if vim.fn.executable(cli_path) == 0 then
		health.error("CLI binary not executable: " .. cli_path)
		health.info("Run: chmod +x " .. cli_path)
		return
	end

	health.ok("CLI binary found and executable: " .. cli_path)

	-- Check configuration
	if notare.config.confluence_url == "" then
		health.warn("NOTARE_URL not set")
		health.info("Set environment variable or pass in setup()")
	else
		health.ok("Notare URL configured: " .. notare.config.confluence_url)
	end

	if notare.config.confluence_username == "" then
		health.warn("NOTARE_USERNAME not set")
	else
		health.ok("Notare username configured")
	end

	if notare.config.confluence_api_token == "" then
		health.warn("NOTARE_API_TOKEN not set")
	else
		health.ok("Notare API token configured")
	end

	-- Check dependencies
	local has_telescope = pcall(require, "telescope")
	if has_telescope then
		health.ok("Telescope installed")
	else
		health.error("Telescope not found")
		health.info("Install telescope.nvim: https://github.com/nvim-telescope/telescope.nvim")
	end

	local has_plenary = pcall(require, "plenary")
	if has_plenary then
		health.ok("Plenary installed")
	else
		health.error("Plenary not found")
		health.info("Install plenary.nvim: https://github.com/nvim-lua/plenary.nvim")
	end

	-- Test CLI execution
	health.info("Testing CLI execution...")
	local handle = io.popen(cli_path .. " spaces list 2>&1")
	if handle then
		local result = handle:read("*a")
		handle:close()

		if result:match("NOTARE_URL") or result:match("API") then
			health.ok("CLI executes successfully (credentials may need setup)")
		elseif result:match("Error") or result:match("error") then
			health.warn("CLI execution returned error (check credentials)")
			health.info(result:sub(1, 100))
		else
			health.ok("CLI execution test passed")
		end
	else
		health.error("Failed to execute CLI")
	end
end

return M
