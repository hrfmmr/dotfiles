local util = require("lspconfig.util")
local path = util.path

local function get_python_path(root_dir)
	-- Use activated virtualenv.
	if vim.env.VIRTUAL_ENV then
		return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
	end

	root_dir = root_dir or vim.loop.cwd() or vim.fn.getcwd()

	-- Find and use virtualenv in workspace directory.
	for _, pattern in ipairs({ "*", ".*" }) do
		local match = vim.fn.glob(path.join(root_dir, pattern, "pyvenv.cfg"))
		if match ~= "" then
			return path.join(path.dirname(match), "bin", "python")
		end
	end

	-- Fallback to system Python.
	return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

return {
	on_new_config = function(new_config, root_dir)
		new_config.settings = new_config.settings or {}
		new_config.settings.python = new_config.settings.python or {}
		new_config.settings.python.pythonPath = get_python_path(root_dir)
	end,
}
