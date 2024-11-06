local M = {}

function system_cmd(cmd, opts)
  opts = opts or {}
  local text = vim.system(cmd, { text = true }):wait().stdout
  if opts.text then
    return text
  end
  lines = {}
  for line in string.gmatch(text, '[^\n]+') do
    table.insert(lines, line)
  end
  return lines
end

function escape_pattern(text)
  return text:gsub('([^%w])', '%%%1')
end

M.select = function()
  local contents = function(cb)
    coroutine.wrap(function()
      local co = coroutine.running()

      local panes = system_cmd { 'tmux', 'list-panes', '-F', '#{pane_id}' }
      local current_pane = system_cmd({ 'sh', '-c', 'echo $TMUX_PANE ' })[1]

      local project_files = system_cmd { 'fd', '--color=never', '--type', 'f', '--hidden', '--follow', '--exclude', '.git' }
      local num_history_lines = 10000

      local contents = ''

      for _, pane_id in ipairs(panes) do
        if pane_id ~= current_pane then
          local content = system_cmd({ 'sh', '-c', 'tmux capture-pane -p -t ' .. pane_id .. ' -S ' .. -num_history_lines }, { text = true })
          contents = content .. '\n'
        end
      end

      local files = {}
      for _, file in ipairs(project_files) do
        local pattern = escape_pattern(file)
        for match in string.gmatch(contents, pattern .. ':%d+') do
          table.insert(files, match)
        end
        for match in string.gmatch(contents, pattern) do
          table.insert(files, match)
        end
      end

      local hash = {}
      for _, entry in ipairs(files) do
        if not hash[entry] then
          hash[entry] = true
          cb(entry, function(err)
            coroutine.resume(co)
            if err then
              cb(nil)
            end
          end)
          coroutine.yield()
        end
      end
      -- done
      cb(nil)
    end)()
  end

  local core = require 'fzf-lua.core'
  local defaults = require 'fzf-lua.defaults'
  local config = require 'fzf-lua.config'
  local opts = {
    previewer = defaults._default_previewer_fn,
    prompt = 'Tmux Files> ',
    file_icons = true and defaults._has_devicons,
    color_icons = true,
    _actions = function()
      return defaults.globals.actions.files
    end,
    _cached_hls = { 'path_linenr' },
  }
  opts = config.normalize_opts(opts, {})
  if not opts then
    return
  end
  opts = core.set_header(opts, { 'cwd' })
  opts = core.set_fzf_field_index(opts)
  return core.fzf_exec(contents, opts)
end

M.select()

return M
