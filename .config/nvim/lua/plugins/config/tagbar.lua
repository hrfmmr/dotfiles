return function()
	vim.cmd([[
  nmap <Leader>c :TagbarToggle<CR>
  ]])

	-- Swift support for Tagbar
	vim.g.tagbar_type_swift = {
		ctagstype = 'Swift',
		kinds = {
			'n:Enums',
			't:Typealiases',
			'p:Protocols',
			's:Structs',
			'c:Classes',
			'f:Functions',
			'v:Variables',
			'e:Extensions'
		},
		sort = 0
	}
end
