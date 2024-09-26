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
    return text:gsub("([^%w])", "%%%1")
end

M.list_file_paths = function()
  local panes = system_cmd { 'tmux', 'list-panes', '-F', '#{pane_id}' }
  local current_pane = system_cmd({ 'sh', '-c', 'echo $TMUX_PANE ' })[1]

  local files = system_cmd { 'fd', '--color=never', '--type', 'f', '--hidden', '--follow', '--exclude', '.git' }
  local num_history_lines = 10000
  local results = {}

  local contents = ''

  for _, pane_id in ipairs(panes) do
    if pane_id ~= current_pane then
      local content = system_cmd({ 'sh', '-c', 'tmux capture-pane -p -t ' .. pane_id .. ' -S ' .. -num_history_lines }, { text = true })
      contents = content .. '\n'
    end
  end

  for _, file in ipairs(files) do
    local pattern = escape_pattern(file)
    for match in string.gmatch(contents, pattern .. ":%d+") do
      table.insert(results, match)
    end
    for match in string.gmatch(contents, pattern) do
      table.insert(results, match)
    end
    -- TODO clean duplicated results
  end

  return results
end

M.select = function()
  local items = M.list_file_paths()
  if next(items) == nil then
    return
  end
  local on_choice = function(path)
    if not path then
      return
    end
    local splits = {}
    local i = 1
    for part in string.gmatch(path, '[^:]+') do
      splits[i] = part
      i = i + 1
    end
    local file = splits[1]
    local line_num = splits[2]
    vim.cmd('e ' .. file)
    if line_num then
      vim.api.nvim_call_function('cursor', { line_num, 0 })
    end
  end
  -- Defer the callback to allow the mode to fully switch back to normal after the fzf terminal
  local deferred_on_choice = function(...)
    local args = vim.F.pack_len(...)
    vim.defer_fn(function()
      on_choice(vim.F.unpack_len(args))
    end, 10)
  end
  local ui_select = require 'fzf-lua.providers.ui_select'
  ui_select.ui_select(items, {}, deferred_on_choice)
end

M.select()

return M
