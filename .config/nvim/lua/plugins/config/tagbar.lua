return function()
	vim.cmd([[
  nmap <Leader>c :TagbarToggle<CR>
  ]])

	-- Swift support for Tagbar
	vim.g.tagbar_type_swift = {
		ctagstype = 'swift',
		kinds = {
			'n:enums',
			't:typealiases', 
			'p:protocols',
			's:structs',
			'c:classes',
			'f:functions',
			'v:variables',
			'e:extensions'
		},
		sro = '.',
		kind2scope = {
			c = 'class',
			s = 'struct',
			e = 'extension',
			p = 'protocol',
			n = 'enum'
		},
		scope2kind = {
			class = 'c',
			struct = 's',
			extension = 'e',
			protocol = 'p',
			enum = 'n'
		},
		sort = 0
	}
end
