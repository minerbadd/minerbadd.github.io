-- **CLI for apiMark**...puts api file in specified apiDirectory

local opFiles, apiMark = require("opFiles"), require("apiMark").cli

local function marker(apiPath, verbose) --in lieu of codemark.marker
  return function(file, _) -- second (optional) argument to function applied by `opFiles`
    local checkings, lines, outPath, helpPath, apiPathZ  = apiMark(file, nil, apiPath)
    for _, checking in ipairs(checkings) do print(checking) end
    if apiPathZ and verbose then print("Updating "..apiPathZ) end
    if helpPath and verbose then print("help file is "..helpPath) end
    if outPath and verbose then print(lines.." lines output to "..outPath) end
  end
end

local function apiFiles(inDirectory, apiDirectory, apiFile, verbose)
  opFiles(marker(apiDirectory..apiFile, verbose), inDirectory, "lua", apiDirectory)
end

return apiFiles

