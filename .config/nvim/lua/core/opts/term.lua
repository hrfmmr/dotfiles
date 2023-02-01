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
