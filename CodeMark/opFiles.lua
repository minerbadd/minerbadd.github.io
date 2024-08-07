-- **Batch CodeMark operations generating ZBS completions, help files, and markdown documentation** 
---@diagnostic disable-next-line: undefined-field
require("lfs"); local lfs = _G.lfs -- to surpress lint warnings

local function checkFile(inName, directory, extension)
  if inName == "." or inName == ".." or not string.match(inName, "(%."..extension..")$") then return end
  local path = directory..'/'..inName; local attributes = lfs.attributes(path)
  assert (type(attributes) == "table"); if attributes.mode == "directory" then return end
  return path
end

local function opFiles(op, inDirectory, extension, outDirectory)
  for inName in lfs.dir(inDirectory) do
    local inPath = checkFile(inName, inDirectory, extension); if inPath then
      local outPath = outDirectory and outDirectory..inName
      op(inPath, outPath, extension)  
    end
  end
end

return opFiles
