vim.api.nvim_create_user_command("ReloadConfig", function()
	require("utils").reloadConfig()
end, { desc = "Reload nvim config" })

vim.api.nvim_create_user_command("Scriptnames", function()
	vim.api.nvim_exec(
		[[
        :tabnew
        :put =execute('scriptnames')
    ]],
		false
	)
end, { desc = "List all loaded vim/lua script names on new buffer" })

vim.cmd([[
function! s:Jq(...)
  if 0 == a:0
    let l:arg = "."
  else
    let l:arg = a:1
  endif
  execute "%! jq \"" . l:arg . "\""
endfunction
command! -nargs=? Jq call s:Jq(<f-args>)
]])
