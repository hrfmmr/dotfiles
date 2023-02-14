return function()
	vim.cmd([[
  autocmd! BufWritePre *.tf execute ':TerraformFmt'
  ]])
end
