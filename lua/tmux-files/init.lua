local uv = vim.uv or vim.loop
local config = require 'fzf-lua.config'
local core = require 'fzf-lua.core'
local defaults = require 'fzf-lua.defaults'
local make_entry = require 'fzf-lua.make_entry'
local utils = require 'fzf-lua.utils'

local M = {}

M.select = function(opts)
  opts = config.normalize_opts(opts, {
    prompt      = "Tmux Files> ",
    file_icons  = true and defaults._has_devicons,
    color_icons = true,
    git_icons   = false,
    previewer   = defaults._default_previewer_fn,
    cwd_only    = true,
    cwd         = nil,
    _actions    = function() return defaults.globals.actions.files end,
    cmd         = string.gsub([=[tmux list-panes -F "#{pane_id}" | grep -Fvx $TMUX_PANE | xargs -I {} tmux capture-pane -p -t {} -S -10000 | grep -oiE "(^|^\.|[[:space:]]|[[:space:]]\.|[[:space:]]\.\.|^\.\.)[[:alnum:]~_-]*/[][[:alnum:]_.#$%&+=/@-]*(:\d+(:\d+)?)?" | awk '{$1=$1};1' | sort -u]=], [[\$TMUX_PANE]], vim.env.TMUX_PANE),
  })
  if not opts then return end

  opts.fn_transform = function(item)
    local s = utils.strsplit(item, ":")
    local filepath = item
    if #s > 1 then
      filepath = s[1]
    end
    if opts.cwd_only and string.match(filepath, "%.%./") then
      return nil
    end
    if utils.path_is_directory(filepath) then return nil end
    -- FIFO blocks `fs_open` indefinitely (#908)
    if utils.file_is_fifo(filepath, uv.fs_stat(filepath)) or not utils.file_is_readable(filepath) then
      return nil
    end

    return make_entry.file(item, opts)
  end

  opts = core.set_fzf_field_index(opts)
  core.fzf_exec(opts.cmd, opts)
end

return M
