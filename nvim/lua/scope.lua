local M = {}
local scope_types = {
  "class_declaration",
  "struct_declaration",
  "function_declaration",
  "enum_declaration",
  "protocol_declaration",
}
local stack = {}
local function get_scope_node()
  local node = vim.treesitter.get_node()
  while node do
    for _, t in ipairs(scope_types) do
      if node:type() == t then
        return node
      end
    end
    node = node:parent()
  end
end
M.enter = function()
  local node = get_scope_node()
  if not node then
    print("No scope found")
    return
  end
  local start_row, _, end_row, _ = node:range()
  if #stack > 0 and stack[#stack].start_row == start_row then
    return
  end
  local original_buf = vim.api.nvim_get_current_buf()
  local all_lines = vim.api.nvim_buf_get_lines(original_buf, 0, -1, false)
  local scope_lines = vim.list_slice(all_lines, start_row + 1, end_row + 1)

  -- calcular indentación mínima
  local min_indent = math.huge
  for _, line in ipairs(scope_lines) do
    if line ~= "" then
      local indent = #line:match("^(%s*)")
      if indent < min_indent then
        min_indent = indent
      end
    end
  end
  if min_indent == math.huge then min_indent = 0 end

  -- quitar indentación base
  local dedented = {}
  for _, line in ipairs(scope_lines) do
    table.insert(dedented, line:sub(min_indent + 1))
  end

  table.insert(stack, {
    original_buf = original_buf,
    start_row = start_row,
    end_row = end_row,
    cursor = vim.api.nvim_win_get_cursor(0),
    min_indent = min_indent
  })
  local tmp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, dedented)
  vim.bo[tmp_buf].filetype = vim.bo[original_buf].filetype
  vim.api.nvim_set_current_buf(tmp_buf)
end
M.exit = function()
  if #stack == 0 then
    print("Already at top level")
    return
  end
  local prev = table.remove(stack)
  local tmp_buf = vim.api.nvim_get_current_buf()
  local modified_lines = vim.api.nvim_buf_get_lines(tmp_buf, 0, -1, false)

  -- restaurar indentación
  local indent_str = string.rep(" ", prev.min_indent)
  local reindented = {}
  for _, line in ipairs(modified_lines) do
    table.insert(reindented, line ~= "" and indent_str .. line or line)
  end

  vim.api.nvim_set_current_buf(prev.original_buf)
  vim.api.nvim_buf_set_lines(prev.original_buf, prev.start_row, prev.end_row + 1, false, reindented)
  vim.api.nvim_win_set_cursor(0, prev.cursor)
  if vim.bo[prev.original_buf].buftype == "" then
    vim.cmd('silent write')
  end
  vim.api.nvim_buf_delete(tmp_buf, { force = true })
end
M.in_scope = function()
  return #stack > 0
end
M.original_path = function()
  if #stack == 0 then return nil end
  local path = vim.api.nvim_buf_get_name(stack[1].original_buf)
  print("original_path:", path)
  return path
end
M.save = function()
  if #stack == 0 then return end
  local prev = stack[#stack]
  local tmp_buf = vim.api.nvim_get_current_buf()
  local modified_lines = vim.api.nvim_buf_get_lines(tmp_buf, 0, -1, false)

  local indent_str = string.rep(" ", prev.min_indent)
  local reindented = {}
  for _, line in ipairs(modified_lines) do
    table.insert(reindented, line ~= "" and indent_str .. line or line)
  end

  vim.api.nvim_buf_set_lines(prev.original_buf, prev.start_row, prev.end_row + 1, false, reindented)
  if vim.bo[prev.original_buf].buftype == "" then
    vim.api.nvim_buf_call(prev.original_buf, function()
      vim.cmd('silent write')
    end)
  end
end
return M
