vim.api.nvim_create_user_command("ReloadConfig", function()
	require("utils").reloadConfig()
end, { desc = "Reload nvim config" })

vim.api.nvim_create_user_command("Scriptnames", function()
	vim.api.nvim_exec(
		[[
        :tabnew
        :put =execute('scriptnames')
    ]],
		false
	)
end, { desc = "List all loaded vim/lua script names on new buffer" })
