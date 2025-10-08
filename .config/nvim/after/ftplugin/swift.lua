vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

-- Swift-specific settings
vim.opt_local.expandtab = true
vim.opt_local.smartindent = true

-- Enable inlay hints if available
if vim.lsp.inlay_hint then
	vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
end
