
local parser = require('parser')
local ChangeType = parser.ChangeType

local function equal(a, b)
  if a == nil and b == nil then return true end
  if a == nil or b == nil then return false end
  for k, v in pairs(a) do
    if b[k] ~= v then return false end
  end
  return true
end

local function expect(result, message, deepLevel)
	deepLevel = deepLevel or 2
	local name = debug.getinfo(deepLevel, "n").name or "unknown"
	if result then
		print("\u{001B}[92m􁁛\u{001B}[0m  " .. name .. "()")
	else
		print("\u{001B}[91m􀢄\u{001B}[0m  " .. name .. "(): " .. (message or "failed"))
	end
end

local function expectEqual(a, b, message) 
	expect(equal(a,b), message, 3)
end


local diff_added_sample = [[
Index: test.swift
==================================================================
--- test.swift
+++ test.swift
@@ -50,10 +50,11 @@
 
 @objcMembers
 class VimMotionsTests: XCTestCase {
     let sut = VimEngine()
     func test_l_movesCursorRightOneStep() {
+        newline:
         let state = EditorState(text: "hello", cursor: .zero)
         let newState = sut.applyMotion("l", to: state)
         XCTAssertEqual(newState.cursor.column, 1)
     }
 
]]

local diff_deleted_sample = [[
Index: test.swift
==================================================================
--- test.swift
+++ test.swift
@@ -50,10 +50,9 @@
 
 @objcMembers
 class VimMotionsTests: XCTestCase {
     let sut = VimEngine()
     func test_l_movesCursorRightOneStep() {
-        newline:
         let state = EditorState(text: "hello", cursor: .zero)
         let newState = sut.applyMotion("l", to: state)
         XCTAssertEqual(newState.cursor.column, 1)
     }
 
]]

local diff_modified_sample = [[
Index: test.swift
==================================================================
--- test.swift
+++ test.swift
@@ -50,10 +50,10 @@
 
 @objcMembers
 class VimMotionsTests: XCTestCase {
     let sut = VimEngine()
     func test_l_movesCursorRightOneStep() {
-        oldline:
+        newline:
         let state = EditorState(text: "hello", cursor: .zero)
         let newState = sut.applyMotion("l", to: state)
         XCTAssertEqual(newState.cursor.column, 1)
     }
 
]]

local function test_parser_detectsAddedChange()
  local changes = parser.parse_diff(diff_added_sample)
  local expected = { line = 55, type = ChangeType.added }
  expectEqual(changes[1], expected)
end

local function test_parser_detectsDeletedChange()
  local changes = parser.parse_diff(diff_deleted_sample)
  local expected = { line = 55, type = ChangeType.deleted }
  expectEqual(changes[1], expected)
end

local function test_parser_detectsModifiedChange()
  local changes = parser.parse_diff(diff_modified_sample)
  local expected = { line = 55, type = ChangeType.modified }
  expectEqual(changes[1], expected)
end

test_parser_detectsAddedChange()
test_parser_detectsDeletedChange()
test_parser_detectsModifiedChange()
