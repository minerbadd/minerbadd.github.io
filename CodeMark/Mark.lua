--[[
## -- Produce LLS Signature Files, Zerobrane API, Markdown and HTML Documentation
--]]

local apiFiles, signFiles, downFiles = require("apiFiles"), require("signFiles"), require("downFiles")

local function Mark(apiDirectory, apiFile, sourceDirectories, docsDirectories, codeDirectories, verbose)

-- `opFiles` applies `operation` on files matching an `extension` in `directory` derived from `MUSE`
-- as `opfiles(operation, directory, extension, outDirectory)` 

-- `downFiles` supplies a `codedown` closure over `extension` and `verbose` for the `opFiles` operation 
-- `markFiles` supplies a `codemark` closure over `apiFile` and `verbose` and a defaut `lua` extension
-- The constructs reuse file operations in `opFiles` and the `Zerobrane` operations in `apiMark`

  os.remove(apiDirectory..apiFile)-- for fresh start project repository

  for _, sourceDirectory in ipairs(sourceDirectories) do 
    apiFiles(sourceDirectory, apiDirectory, apiFile, verbose)
  end -- two passes to resolve copies
  for _, sourceDirectory in ipairs(sourceDirectories) do 
    apiFiles(sourceDirectory, apiDirectory, apiFile, verbose)
  end

  signFiles.cli(apiDirectory, apiFile, verbose)
  
  for _, directory in ipairs(docsDirectories) do
    downFiles(directory, directory, "md", verbose)
  end

  for index, sourceDirectory in ipairs(sourceDirectories) do
    downFiles(sourceDirectory, codeDirectories[index], "lua", verbose)
  end
end

return Mark