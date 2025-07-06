return {
	-- Command with compiler flags for strict concurrency
	cmd = {
		"sourcekit-lsp",
		"-Xswiftc",
		"-strict-concurrency=complete",
		"-Xswiftc",
		"-swift-version",
		"-Xswiftc",
		"6"
	},
	settings = {
		sourcekit = {
			-- Enable index-while-building for better performance
			["index-while-building"] = true,
			-- Enable background indexing
			["background-indexing"] = true,
			-- Configure build settings
			["build-path"] = ".build",
			-- Enable completion snippets
			["completion-max-results"] = 200,
			-- Configure SDK paths (will be auto-detected if not specified)
			-- ["sdk-path"] = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
			-- Enable experimental features
			["experimental-features"] = {
				"LSPInlayHints",
				"BackgroundPreparation",
			},
		},
	},
	-- Custom initialization options
	init_options = {
		-- Enable semantic highlighting
		semanticHighlighting = true,
		-- Configure indexing behavior
		indexStorePath = ".build/index-store",
		-- Enable background preparation
		backgroundPreparation = true,
		-- Swift compiler flags for strict concurrency
		buildArguments = {
			"-Xswiftc",
			"-strict-concurrency=complete",
			"-Xswiftc",
			"-swift-version",
			"-Xswiftc",
			"6",
		},
	},
	-- File type support
	filetypes = { "swift", "objective-c", "objective-cpp" },
	-- Single file support for standalone Swift files
	single_file_support = true,
	-- Root directory patterns for Swift projects
	root_dir = function(fname)
		local lspconfig_util = require("lspconfig.util")
		return lspconfig_util.root_pattern("Package.swift", "*.xcodeproj", "*.xcworkspace", ".git")(fname)
			or lspconfig_util.path.dirname(fname)
	end,
	-- Custom capabilities
	capabilities = vim.tbl_deep_extend("force", require("plugins.lsp.handler").capabilities, {
		-- Enable inlay hints if supported
		textDocument = {
			inlayHint = {
				dynamicRegistration = true,
			},
		},
	}),
}
