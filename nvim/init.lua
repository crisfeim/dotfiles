vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Opciones básicas
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.signcolumn = "yes"

-- Lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({

  {
    'folke/tokyonight.nvim',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  {
    'stevearc/oil.nvim',
    opts = {},
  },

  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Buscar ficheros' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep,  { desc = 'Buscar en ficheros' })
      vim.keymap.set('n', '<leader>sb', builtin.buffers,    { desc = 'Buscar buffers' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'swift', 'lua' },
        highlight = { enable = true },
      })
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'path' },
        },
      })
    end,
  },

}, {
  ui = { icons = {} },
})

-- Keymaps básicos
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>o', '<cmd>Oil<CR>', { desc = 'Abrir Oil' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>')
vim.keymap.set('n', '<C-l>', '<C-w><C-l>')
vim.keymap.set('n', '<C-j>', '<C-w><C-j>')
vim.keymap.set('n', '<C-k>', '<C-w><C-k>')

vim.g.mapleader = ","

-- LSP
vim.lsp.config('sourcekit', {
  cmd = { 'xcrun', 'sourcekit-lsp' },
  filetypes = { 'swift' },
})
vim.lsp.enable('sourcekit')

vim.diagnostic.config({
  signs = false,
  underline = true,
  virtual_text = false,
})

-- Fossil gutter
require('fossil.gutter')

-- Scope navigation
local scope = require('scope')
vim.keymap.set('n', '<leader>e', scope.enter, { desc = 'Enter scope' })
vim.keymap.set('n', '<leader>q', scope.exit, { desc = 'Exit scope' })
vim.keymap.set('n', 'ZZ', function()
  if scope.in_scope() then
    while scope.in_scope() do
      scope.exit()
    end
    vim.cmd('q')
  else
    vim.cmd('wq')
  end
end)

-- Runner de tests ,t
local test_win = nil
vim.keymap.set('n', '<leader>t', function()
	if scope.in_scope() then
		scope.save()
	else
		vim.cmd('silent write')
	end
  local filepath = scope.in_scope() and scope.original_path() or vim.fn.expand('%')
  if test_win and vim.api.nvim_win_is_valid(test_win) then
    vim.api.nvim_win_close(test_win, true)
  end
  local output = vim.fn.system("zsh -i -c 'xctest " .. filepath .. "' 2>&1")
  local clean_output = output:gsub("\u{001B}%[%d+m", "")
  local lines = vim.split(clean_output, "\n")

  local passes = {}
  local failures = {}
  for _, line in ipairs(lines) do
    if line:match("􁁛") then
      table.insert(passes, line)
    elseif line:match("􀢄") then
      table.insert(failures, line)
    end
  end

  local to_show = {}
  local is_compile_error = #passes == 0 and #failures == 0
  if is_compile_error then
    to_show = lines
  elseif #failures > 0 then
    to_show = failures
  else
    to_show = passes
  end

  if #to_show > 0 then
    vim.cmd('botright 4split | enew')
    test_win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = 'nofile'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, to_show)
    for i, line in ipairs(to_show) do
      if line:match("􁁛") then
        vim.api.nvim_buf_add_highlight(buf, -1, "XCTestPassHL", i - 1, 0, 1)
      elseif line:match("􀢄") then
        vim.api.nvim_buf_add_highlight(buf, -1, "XCTestFailHL", i - 1, 0, 1)
      end
    end
    vim.cmd('wincmd p')
  end

  local curbuf = vim.api.nvim_get_current_buf()
  local sign_group = "xctest_results"
  vim.fn.sign_define("XCTestPass", { text = "􁁛", texthl = "XCTestPassHL" })
  vim.fn.sign_define("XCTestFail", { text = "􀢄", texthl = "XCTestFailHL" })
  vim.api.nvim_set_hl(0, "XCTestPassHL", { fg = "#92ff00" })
  vim.api.nvim_set_hl(0, "XCTestFailHL", { fg = "#ff6b6b" })
  vim.fn.sign_unplace(sign_group, { buffer = curbuf })

  for _, line in ipairs(lines) do
    local name = line:match("test_%S+%(%)") 
    if name then
      name = name:gsub("%(%)$", "")
      local is_pass = line:match("􁁛") ~= nil
      local buflines = vim.api.nvim_buf_get_lines(curbuf, 0, -1, false)
      for i, bufline in ipairs(buflines) do
        if bufline:match("func " .. name) then
          local sign = is_pass and "XCTestPass" or "XCTestFail"
          vim.fn.sign_place(0, sign_group, sign, curbuf, { lnum = i, priority = 6 })
          break
        end
      end
    end
  end
end)
-- Runner genérico ,r
local run_win = nil
vim.keymap.set('n', '<leader>r', function()
  vim.cmd('silent write')
  if run_win and vim.api.nvim_win_is_valid(run_win) then
    vim.api.nvim_win_close(run_win, true)
  end
  local ext = vim.fn.expand('%:e')
  local cmd = ({
    lua   = 'lua',
    swift = 'xctest',
    py    = 'python3',
    js    = 'node',
    sh    = 'bash',
    zsh   = 'zsh',
  })[ext] or 'echo "no runner for ' .. ext .. '"'
  vim.cmd('botright 4split | terminal zsh -i -c "' .. cmd .. ' ' .. vim.fn.expand('%') .. '"')
  run_win = vim.api.nvim_get_current_win()
  vim.cmd('wincmd p')
end)
