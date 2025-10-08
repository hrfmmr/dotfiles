return {
	on_attach = function(client, bufnr)
		-- TypeScriptは外部フォーマッタを使うためLSP側のフォーマット機能を無効化
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
		require("plugins.lsp.handler").on_attach(client, bufnr)
	end,
}
