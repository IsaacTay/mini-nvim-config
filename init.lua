-- Put this at the top of 'init.lua'
local path_package = vim.fn.stdpath('data') .. '/site'
local mini_path = path_package .. '/pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    -- Uncomment next line to use 'stable' branch
    -- '--branch', 'stable',
    'https://github.com/echasnovski/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
end

vim.opt.relativenumber = true
vim.cmd("language en_US")

require('mini.basics').setup({
  options = { extra_ui = true },
})
require('mini.files').setup({
  windows = { preview = true },
  -- mappings = {
  --   go_in = 'L',
  --   go_out = 'H',
  -- }
})
require('mini.icons').setup()
require('mini.ai').setup()
require('mini.cursorword').setup()
require('mini.pairs').setup()
require('mini.comment').setup()
require('mini.indentscope').setup()
require('mini.bracketed').setup()
require('mini.splitjoin').setup()
require('mini.trailspace').setup()
require('mini.tabline').setup()
require('mini.statusline').setup()
require('mini.pick').setup()
require('mini.bufremove').setup()
local miniclue = require('mini.clue')
miniclue.setup({
  triggers = {
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },

    { mode = 'n', keys = '<LocalLeader>' },
    { mode = 'x', keys = '<LocalLeader>' },

    -- `g` key
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },

    -- Registers
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-r>' },
    { mode = 'c', keys = '<C-r>' },

    -- Window commands
    { mode = 'n', keys = '<C-w>' },

    -- `z` key
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },

    -- bracketed
    { mode = 'n', keys = ']' },
    { mode = 'n', keys = '[' },
  },
  clues = {
    -- Enhance this by adding descriptions for <Leader> mapping groups
    -- miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    -- miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers({show_contents=true}),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),

    -- Mapping groups
    { mode = 'n', keys = '<Leader>b', desc = '+Buffers' },
    { mode = 'n', keys = '<Leader>l', desc = '+LSP' },
    { mode = 'n', keys = '<Leader>f', desc = '+File' },
    { mode = 'n', keys = '<Leader>/', desc = '+Search' },

    -- Bracketed
    { mode = 'n', keys = ']b', postkeys = ']' },
    { mode = 'n', keys = ']w', postkeys = ']' },

    { mode = 'n', keys = '[b', postkeys = '[' },
    { mode = 'n', keys = '[w', postkeys = '[' },
  },
})

local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, { desc = desc })
end
local xmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
end

nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>',  'Delete buffer')
nmap_leader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>', 'Wipeout buffer')
nmap_leader('b/', '<cmd>lua MiniPick.builtin.buffers()<CR>', "Search buffers")
nmap_leader('bb', '<cmd>lua MiniPick.builtin.buffers()<CR>', "Search buffers")

nmap_leader('lf', '<Cmd>lua vim.lsp.buf.format()<CR>',     'Format')
nmap_leader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>',     'Rename')
nmap_leader('lR', '<Cmd>lua vim.lsp.buf.references()<CR>', 'References')

nmap_leader('fm', '<cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', "Opens mini.files")
nmap_leader('ft', '<cmd>lua MiniTrailspace.trim()<CR>', "Search files")
nmap_leader('f/', '<cmd>lua MiniPick.builtin.files()<CR>', "Search files")
nmap_leader('ff', '<cmd>lua MiniPick.builtin.files()<CR>', "Search files")

nmap_leader('/h', '<cmd>lua MiniPick.builtin.help()<CR>', "Search help")
nmap_leader('/b', '<cmd>lua MiniPick.builtin.buffers()<CR>', "Search buffers")
nmap_leader('/f', '<cmd>lua MiniPick.builtin.files()<CR>', "Search files")
nmap_leader('//', '<cmd>lua MiniPick.builtin.grep_live()<CR>', "Live grep")
local show_dotfiles = true

local filter_show = function(fs_entry) return true end

local filter_hide = function(fs_entry)
  return not vim.startswith(fs_entry.name, '.')
end

local toggle_dotfiles = function()
  show_dotfiles = not show_dotfiles
  local new_filter = show_dotfiles and filter_show or filter_hide
  MiniFiles.refresh({ content = { filter = new_filter } })
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id
    -- Tweak left-hand side of mapping to your liking
    vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = buf_id })
  end,
})

-- Set focused directory as current working directory
local set_cwd = function()
  local path = (MiniFiles.get_fs_entry() or {}).path
  if path == nil then return vim.notify('Cursor is not on valid entry') end
  vim.fn.chdir(vim.fs.dirname(path))
end

-- Yank in register full path of entry under cursor
local yank_path = function()
  local path = (MiniFiles.get_fs_entry() or {}).path
  if path == nil then return vim.notify('Cursor is not on valid entry') end
  vim.fn.setreg(vim.v.register, path)
end

-- Open path with system default handler (useful for non-text files)
local ui_open = function() vim.ui.open(MiniFiles.get_fs_entry().path) end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local b = args.data.buf_id
    vim.keymap.set('n', 'g~', set_cwd,   { buffer = b, desc = 'Set cwd' })
    vim.keymap.set('n', 'gX', ui_open,   { buffer = b, desc = 'OS open' })
    vim.keymap.set('n', 'gy', yank_path, { buffer = b, desc = 'Yank path' })
  end,
})
