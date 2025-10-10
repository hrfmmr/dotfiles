local nvim_lsp = require("lspconfig")

return {
	root_dir = nvim_lsp.util.root_pattern("deno.json", "deno.jsonc"),
	init_options = {
		enable = true,
		lint = true,
		unstable = true,
		suggest = {
			imports = {
				hosts = {
					["https://deno.land"] = true,
					["https://jsr.io"] = true,
					["https://esm.sh"] = true,
					["npm:"] = true,
				},
			},
		},
	},
}
