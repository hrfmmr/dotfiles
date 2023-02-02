return {
	reloadConfig = function()
		for name, _ in pairs(package.loaded) do
			print("Reload package:" .. name)
			package.loaded[name] = nil
		end
		dofile(vim.env.MYVIMRC)
	end,
}
