return function()
	vim.cmd([[
  autocmd! Filetype TelescopePrompt let b:autopairs_enabled = 0
  ]])
end
