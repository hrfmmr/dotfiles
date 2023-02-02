-- GUI
vim.g.terminal_color_0 = "#232c33"
vim.g.terminal_color_1 = "#99736e"
vim.g.terminal_color_2 = "#78a090"
vim.g.terminal_color_3 = "#bfb7a1"
vim.g.terminal_color_4 = "#7c9fa6"
vim.g.terminal_color_5 = "#BF9C86"
vim.g.terminal_color_6 = "#99BFBA"
vim.g.terminal_color_7 = "#f0f0f0"
vim.g.terminal_color_8 = "#70838c"
vim.g.terminal_color_9 = "#99736e"
vim.g.terminal_color_10 = "#78a090"
vim.g.terminal_color_11 = "#bfb7a1"
vim.g.terminal_color_12 = "#7c9fa6"
vim.g.terminal_color_13 = "#BF9C86"
vim.g.terminal_color_14 = "#99BFBA"
vim.g.terminal_color_15 = "#f0f0f0"

-- Event hooks
local group = vim.api.nvim_create_augroup("terminal_command", {})
local function terminal_autocmd(event)
	return function(cb)
		local opts = { group = group, pattern = "term://*" }
		if type(cb) == "string" then
			opts.command = cb
		else
			opts.callback = cb
		end
		vim.api.nvim_create_autocmd(event, opts)
	end
end

terminal_autocmd("TermOpen")(function()
	vim.opt_local.scrolloff = 0
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.cursorline = false
	vim.cmd.startinsert()
end)
