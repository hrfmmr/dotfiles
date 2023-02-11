local M = {}

local function lsp_highlight_document(client)
	-- Set autocommands conditional on server_capabilities
	if client.server_capabilities.documentHighlightProvider then
		vim.cmd(
			[[
            augroup lsp_document_highlight
              autocmd! * <buffer>
              autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
              autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
            augroup END
            ]],
			false
		)
	end
end

local function lsp_keymaps(bufnr)
	local bufopts = { silent = true, buffer = bufnr }
	vim.keymap.set("n", "<C-g><C-d>", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "<C-g><C-t>", vim.lsp.buf.type_definition, bufopts)
	vim.keymap.set("n", "<C-g><C-r>", vim.lsp.buf.references, bufopts)
	vim.keymap.set("n", "<C-g><C-i>", vim.lsp.buf.implementation, bufopts)
	vim.keymap.set("n", "<C-g><C-f>", vim.lsp.buf.format, bufopts)
end

M.on_attach = function(client, bufnr)
	-- Disable client specific features, e.g. to use null-ls formatting instead
	local clients = { "gopls", "sumneko_lua", "sqls" }
	for _, v in ipairs(clients) do
		if client.name == v then
			client.server_capabilities.documentFormattingProvider = false
		end
	end
	lsp_keymaps(bufnr)
	lsp_highlight_document(client)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_ok then
	return
end

M.capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

return M
