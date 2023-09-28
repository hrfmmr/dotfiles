return {
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-fzf-native.nvim",
		"nvim-telescope/telescope-frecency.nvim",
		"nvim-telescope/telescope-ghq.nvim",
		"nvim-telescope/telescope-github.nvim",
	},
	config = function()
		-- setup {{{
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				sorting_strategy = "ascending",
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
			pickers = {
				live_grep = {
					additional_args = function(opts)
						return { "--hidden" }
					end,
				},
				grep_string = {
					additional_args = function(opts)
						return { "--hidden" }
					end,
				},
			},
		})
		-- This is needed to setup telescope-fzf-native. It overrides the sorters
		-- in this.
		telescope.load_extension("fzf")
		telescope.load_extension("frecency")
		telescope.load_extension("ghq")
		telescope.load_extension("gh")
		-- }}}

		-- keymaps for builtin {{{
		local builtin = require("telescope.builtin")
		local get_file_dir = function()
			-- get expand('%:h') if buffer has filename, otherwise use $CWD
			local sibling = vim.fn.expand("%:h")
			if sibling ~= nil and sibling ~= "" then
				return sibling
			end
			return vim.fn.getcwd()
		end

		-- files
		local find_files_opts = { find_command = { "rg", "--files", "--hidden", "-g", "!.git" } }
		vim.keymap.set("n", "<C-u>u", function()
			builtin.find_files(find_files_opts)
		end, {})
		vim.keymap.set("n", "<C-u><C-u>", function()
			local opts = vim.tbl_deep_extend("force", find_files_opts, {
				default_text = "'" .. vim.fn.expand("<cword>"),
			})
			builtin.find_files(opts)
		end, {})
		vim.keymap.set("n", "<M-u><M-u>", function()
			local opts = vim.tbl_deep_extend("force", find_files_opts, { cwd = get_file_dir(), hidden = true })
			builtin.find_files(opts)
		end, {})
		vim.keymap.set("n", "<C-u><C-h>", "<cmd>Telescope oldfiles<cr>", {})
		-- buffers
		vim.keymap.set("n", "<C-u><C-b>", builtin.buffers, {})
		-- grep
		vim.keymap.set("n", "<C-u><C-g>", builtin.grep_string, {})
		vim.keymap.set("n", "<M-u><M-g>", function()
			builtin.grep_string({ cwd = get_file_dir() })
		end, {})
		vim.keymap.set("n", "<C-u>g", builtin.live_grep, {})
		vim.keymap.set("n", "<M-u>g", function()
			builtin.live_grep({ cwd = get_file_dir() })
		end, {})
		vim.keymap.set("n", "<M-b>g", function()
			builtin.live_grep({ grep_open_files = true })
		end, {})
		-- buffer lines
		vim.keymap.set("n", "<C-u><C-l>", function()
			builtin.current_buffer_fuzzy_find({ skip_empty_lines = true })
		end, {})
		-- file types
		vim.keymap.set("n", "<C-u><C-t>", builtin.filetypes, {})
		-- lsp diagnostics
		vim.keymap.set("n", "<C-u><C-e>", builtin.diagnostics, {})
		-- lsp
		vim.keymap.set("n", "<C-u>sr", builtin.lsp_references)
		vim.keymap.set("n", "<C-u>sd", builtin.lsp_document_symbols)
		vim.keymap.set("n", "<C-u>sw", ":Telescope lsp_workspace_symbols query=")
		-- resume
		vim.keymap.set("n", "<C-u><C-r>", builtin.resume, {})
		-- command history
		vim.keymap.set("n", "<C-u>ch", builtin.command_history, {})
		vim.keymap.set("n", "<C-u>cr", builtin.commands, {})
		-- git
		vim.keymap.set("n", "<C-u>Gc", builtin.git_commits, {})
		vim.keymap.set("n", "<C-u>Gg", builtin.git_bcommits, {})
		vim.keymap.set("n", "<C-u>Gr", builtin.git_branches, {})
		-- }}}

		-- keymaps for extensions {{{
		local function extensions(t)
			local name, prop, opt = t[1], t[2], t[3] or {}
			return function()
				return telescope.extensions[name][prop](opt)
			end
		end

		-- frecency
		vim.keymap.set("n", "<C-u>H", extensions({ "frecency", "frecency" }))
		-- ghq
		vim.keymap.set(
			"n",
			"<C-u>hq",
			extensions({
				"ghq",
				"list",
				{
					attach_mappings = function(_)
						local actions_set = require("telescope.actions.set")
						actions_set.select:replace(function(_, _)
							local from_entry = require("telescope.from_entry")
							local actions_state = require("telescope.actions.state")
							local entry = actions_state.get_selected_entry()
							local dir = from_entry.path(entry)
							builtin.git_files({ cwd = dir, show_untracked = true })
						end)
						return true
					end,
				},
			})
		)
		-- }}}
	end,
}
