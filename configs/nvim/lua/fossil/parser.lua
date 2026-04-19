local ChangeType = { 
	added = "added",
	deleted = "deleted",
	modified = "modified"
}
local T = {}
T.ChangeType = ChangeType
T.parse_diff = function(diff_output)
  local changes = {}
  local current_line = 0
  local pending_delete = nil
  for line in diff_output:gmatch("[^\n]+") do
    local new_start = line:match("^@@[^+]+%+(%d+)")
    if new_start then
      if pending_delete then
        table.insert(changes, { line = pending_delete, type = ChangeType.deleted })
        pending_delete = nil
      end
      current_line = tonumber(new_start) - 1
    elseif line:match("^%-%-%- ") then
      -- cabecera, ignorar
    elseif line:match("^%-") then
      if pending_delete then
        table.insert(changes, { line = pending_delete, type = ChangeType.deleted })
      end
      pending_delete = current_line + 1
    elseif line:match("^%+%+%+ ") then
      -- cabecera, ignorar
    elseif line:match("^%+") then
      current_line = current_line + 1
      if pending_delete then
        table.insert(changes, { line = current_line, type = ChangeType.modified })
        pending_delete = nil
      else
        table.insert(changes, { line = current_line, type = ChangeType.added })
      end
    else
      if pending_delete then
        table.insert(changes, { line = pending_delete, type = ChangeType.deleted })
        pending_delete = nil
      end
      current_line = current_line + 1
    end
  end
  if pending_delete then
    table.insert(changes, { line = pending_delete, type = ChangeType.deleted })
  end
  return changes
end
return T
