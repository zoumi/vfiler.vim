local core = require 'vfiler/core'

local Syntax = {}
Syntax.__index = Syntax

function Syntax.new(configs)
  return setmetatable({
    _syntaxes = configs.syntaxes,
    _end_mark = configs.end_mark,
    _ignore_group = configs.ignore_group,
  }, Syntax)
end

function Syntax:syntaxes()
  local end_mark = core.vim_pattern_escape(self._end_mark)
  local ignores = {end_mark}
  local commands = {}
  for _, syntax in pairs(self._syntaxes) do
    local start_mark = core.vim_pattern_escape(syntax.start_mark)
    table.insert(ignores, start_mark)

    local pattern = string.format('%s.\\+%s', start_mark, end_mark)
    local command = core.syntax_match_command(
      syntax.group, pattern, {contains = self._ignore_group}
    )
    table.insert(commands, command)
  end
  -- Ignore syntax
  local ignore_syntax = core.syntax_match_command(
    self._ignore_group,
    table.concat(ignores, '\\|'),
    {contained = true, conceal = true}
  )
  table.insert(commands, ignore_syntax)
  return commands
end

function Syntax:highlights()
  local commands = {}
  for _, syntax in pairs(self._syntaxes) do
    table.insert(
      commands, core.link_highlight_command(syntax.group, syntax.highlight)
    )
  end
  table.insert(
    commands, core.link_highlight_command(self._ignore_group, 'Ignore')
  )
  return commands
end

function Syntax:surround_string(name, str)
  return self._syntaxes[name].start_mark .. str .. self._end_mark
end

return Syntax
