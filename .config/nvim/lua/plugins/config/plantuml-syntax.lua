return function()
	vim.cmd([[
  augroup PlantUMLGroup
    autocmd!
    au FileType plantuml command! OpenUml :!google-chrome %
  augroup END
  ]])
end
