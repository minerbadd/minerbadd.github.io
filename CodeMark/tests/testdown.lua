-- **Tests for codedown line**

local executionDirectory = arg[0]:match('.*[/\\]') -- get execution directory
local codedown = dofile(executionDirectory.."codedown.lua").test

local data = {
  '--:> situation: _Dead reckoning, as `{position = {:}, facing = ":", fuel = #:, level = ":"}`._',
 "\n",
 [[
 
 ]],
  "uncoded text <code> coded material </code> more uncoded text <code> more coded material </code> finish",
  "## Section H2 and <code> some code </code> for the section",
}

for i, item in ipairs(data) do 
  local result = codedown(item)
  print(i, result)
end
