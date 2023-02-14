return {
	dependencies = {
		"Shougo/vimproc.vim",
	},
	config = function()
		vim.cmd([[
    nmap <silent> <Leader>ru :QuickRun<CR>
    let g:quickrun_config = {}
    "let g:quickrun_config._ = {
    "\   'runner' : 'vimproc',
    "\   'runner/vimproc/updatetime' : 40,
    "\}
    let g:quickrun_config.python = {
    \ 'command': expand('~/.pyenv/shims/python'),
    \}
    let g:quickrun_config.swift = {
    \ 'command': 'xcrun',
    \ 'cmdopt': 'swift',
    \ 'exec': '%c %o %s',
    \}
    let g:quickrun_config.haskell = {
    \ 'command': 'stack',
    \ 'cmdopt': 'runghc',
    \}
    ]])
	end,
}
