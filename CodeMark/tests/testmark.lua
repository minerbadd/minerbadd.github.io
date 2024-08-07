-- **Tests for codedown line**

local executionDirectory = arg[0]:match('.*[/\\]') -- get execution directory
local function splitFiles(path)   -- make a table split by \ or /
    local files = {}; for name in string.gmatch(path, "([^/\\]+)[/\\]?") do table.insert(files, name) end 
    return files
end

local files = splitFiles(executionDirectory); 
local CodeMark =  table.concat(files, "/", 1, #files - 1).."/"
local testline = dofile(CodeMark.."codemark.lua").line

local data = {
  '--:: move.to(:xyzf:, first: ":"?) -> _Current situation to x, z, y, and optionally face._ -> `"done", #:, xyzf &!recovery`',
  '--:: field.plot(commands: field.plotSpan, fieldsOp: (:), fieldOpName: ":", plots: #:, offset: xyz?) -> _Plots_ -> `report: ":" &: &!`',

  '--:: `_field.makeBounds(nearPlace: ":", farPlace: ":")` -> _Get coordinate pair for named places._ -> `xyz, xyz, #:, #:`'
}

for i, item in ipairs(data) do 
  local result = testline(item, "")
  print(i, result)
end
