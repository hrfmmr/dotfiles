return function()
	vim.cmd([[
  autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescript.tsx
  ]])
end
