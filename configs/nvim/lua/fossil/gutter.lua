local parser = require('fossil.parser')
local sign_group = "fossil_diff"

vim.fn.sign_define("FossilAdded",    { text = "+", texthl = "FossilAddedHL" })
vim.fn.sign_define("FossilDeleted",  { text = "-", texthl = "FossilDeletedHL" })
vim.fn.sign_define("FossilModified", { text = "~", texthl = "FossilModifiedHL" })

vim.api.nvim_set_hl(0, "FossilAddedHL",    { fg = "#92ff00" })
vim.api.nvim_set_hl(0, "FossilDeletedHL",  { fg = "#ff6b6b" })
vim.api.nvim_set_hl(0, "FossilModifiedHL", { fg = "#ffff00" })

local M = {}
local is_fossil = {}

M.update_realtime = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then return end

  local tmp = "/tmp/fossil_gutter_" .. vim.fn.fnamemodify(filepath, ":t")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local f = io.open(tmp, "w")
  f:write(table.concat(lines, "\n") .. "\n")
  f:close()
  local output = vim.fn.system("fossil cat " .. vim.fn.shellescape(filepath) .. " > /tmp/fossil_original && diff -u /tmp/fossil_original " .. tmp)

  vim.fn.sign_unplace(sign_group, { buffer = bufnr })
  local changes = parser.parse_diff(output)
  for _, change in ipairs(changes) do
    if change.line > 0 then
      local sign = change.type == "added" and "FossilAdded"
                or change.type == "modified" and "FossilModified"
                or "FossilDeleted"
      vim.fn.sign_place(0, sign_group, sign, bufnr, { lnum = change.line, priority = 5 })
    end
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath == "" then return end
    local result = vim.fn.system("fossil status " .. vim.fn.shellescape(filepath) .. " 2>&1")
    is_fossil[filepath] = not result:match("not within an open checkout")
    if is_fossil[filepath] then
      M.update_realtime()
    end
  end
})

vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
  pattern = "*",
  callback = function()
    local filepath = vim.api.nvim_buf_get_name(0)
    if not is_fossil[filepath] then return end
    M.update_realtime()
  end
})

return M
