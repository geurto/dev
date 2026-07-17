-- Theme configuration
local function setup_everforest()
	vim.g.everforest_background = "hard"
	vim.g.everforest_better_performance = 1
	vim.g.everforest_enable_italic = 1

	vim.cmd.colorscheme("everforest")

	vim.cmd([[
    augroup EverforestReload
      autocmd!
      autocmd VimEnter * lua vim.defer_fn(function() vim.cmd('doautocmd ColorScheme') end, 10)
    augroup END
    ]])
end

setup_everforest()
