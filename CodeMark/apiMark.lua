-- **Generate summary and update ZBS completion and API information for edited file.**
-- **Note: table returned by loading this file adds an entry for CLI batch operation (and debug) not in ZBS package spec.** 

-- _Executing the_ `..codemark.lua` _file returns a table with an_ `api` _keyed entry whose value overrides the project name_.
-- _Example:_ `return {api = 'test', }`. _Edit the ZBS preference file to set the `api` to the project name, e.g.,_ `api = {'test'}`
-- _Also edit the ZBS preference ("Preferences" in the "Edit" menu) to set the tooltip width_ `acandtip.width = 120`
-- _The default project name is the name of the directory containing the directory of the summary files_.
-- _API definitions are replaced but not erased. They can be erased by deleting and rebuilding the project API file._

---@diagnostic disable-next-line: undefined-field
require("lfs"); local lfs = _G.lfs -- to surpress lint warnings

-- **Some extractions to get the critical parts of text and ignore the rest**

local function firstWords(text) 
  local name = string.match(text, "(.-)[:%(%s]"); if not name then return "" end
  return string.match(name, "([%a%d_]+).?(%a*%d*)") -- second = "" if no second
end 

local function stripFormat(text) -- first led by spaces, surrounded by * and _; second rest less trailing _, *, spaces
  local first, second = string.match(text or "", "[_%*%s`]*(%w*)[_%*]*(.-)[_%*%s`]*$"); 
  return (first or "")..(second or "")
end

local function stripUnder(text) return string.match(text, "[_]*(.-)[_]*$") or "" end

local function commaSplit(text)
  local items = {}; items[#items + 1] = string.match(text, "([^,]*),?"); -- first
  for item in string.gmatch(text, ",([^,]*)") do items[#items + 1] = string.gsub(item, "%s", "") end
  return items
end

-- **Find absolute path for a relative path given an absolute path with a point in common with the relative path**
-- _The absolute path for the file being edited provides the context for the output file and the ZBS api file._

local function splitFiles(path)   -- make a table split by \ or /
  local files = {}; for name in string.gmatch(path, "([^/\\]+)[/\\]?") do files[#files + 1] = name 
  end; return files
end

local function checkNode(project, node)
  local attributes = lfs.attributes(node); if type(attributes) == "table" and attributes.mode == "directory" then 
    for name in lfs.dir(node) do if project == name then return name end end 
  end
end

local function match(project, contextFiles) -- look for common node back from end of context path
  for i = #contextFiles - 1, 1, -1 do 
    if project == contextFiles[i] then return i end  
    local path = table.concat(contextFiles, "/", 1, i)
    local name = checkNode(project, path); 
    if name then return i + 1, name end
  end
end

local function merge(matchPoint, files, contextFiles, name) -- 
  local merged = {}; for i = 1, matchPoint - 1 do merged[i] = contextFiles[i] end --  prepend context up to matchpoint 
  merged[matchPoint] = name or contextFiles[matchPoint]
  for j = 2, #files do merged[matchPoint + j - 1] = files[j] end
  return merged
end

local function absolutePath(filePath, contextPath) -- same volume
  -- absolutePath(":filePath", ":contextPath") -> _Absolute context, relative file gets absolute file_ -> `nil | ":path"`
  local fileNames, contextFiles = splitFiles(stripUnder(filePath)), splitFiles(stripUnder(contextPath))
  local matchPoint, name  = match(fileNames[1], contextFiles); 
  if not matchPoint then error("codemark:absolutePath: no common point in paths for "..filePath.." and "..contextPath) end 
  local merged = merge(matchPoint, fileNames, contextFiles, name)
  return table.concat(merged, "/") -- absolute path for (relative) filePath
end

-- **Whole lot of string parsing going on**
local marks = {-- code marks matched to get mark kinds 
  ["--:!"] = "api", ["--:?"] = "help", ["--:~"] = "list", -- fileMarks, one per file, just included in output file
  ["--:+"] = "more", ["--:#"] = "head",  ["--:<"] = "word", -- comment marks, first word of `word` referened by `copy`
  ["--:="] = "copy",   -- sign used to retrieve line from ZBS completion values hidden by `word`, `face`, and `cli`
  ["--:-"] = "cli", ["--:|"] = "lib",  -- `cli` to help files, `lib`: one for each library in the file
  ["--::"] = "face", ["--:>"] = "type",  -- (inter)face function and type annotations included in api file
}

local markSplit = "(%-%-:.)%s*(.*)" -- mark to get kind, rest of the line may be empty
local fileSplit = "(.+)<%-(.+)%->%s*(.+)" -- fileMark <- descriptive text -> [project:]..output path
local commentSplit = "(.+)" -- after the code mark the rest of `more` and `head` lines is just text as sign
local libSplit = "(.-):(.+)$" -- sign (signature) and text follow code mark, text may have out
local faceSplit = "(.-)%->(.-)%->(.+)" -- sign -> text -> out 
local typeSplit = "(.-):(.-)%->(.+)" -- sign: text -> out 
local cliSplit =  "(.-)->%s*(.+)" -- sign -> text
local copySplit = "([%a%d%S]+):%s*(.-)$" -- sign: text

local splits = { -- for each kind, split rest of code mark line after kind mark into sign, text, and out
  api = fileSplit, help = fileSplit, list = fileSplit, -- sign, text, out 
  more = commentSplit, head = commentSplit, -- sign part starts off being most of the line
  cli = cliSplit, copy = copySplit, type = typeSplit, lib = libSplit,  face = faceSplit,  word = commentSplit,
  inner = faceSplit, check = typeSplit,
}

local function parseSign(sign) -- function name including library ends before ( or [ or {, signature follows and the rest
  local name, signaturePart = string.match(sign, "(.-)(%b())")
  local signature = string.match(signaturePart, "^%((.-)%)$")
  return signature, name
end

local function underWord(text) return "_"..(stripFormat(text) or "").."_" end -- for ZBSapi lookup

-- **Get project name (for ZBS api file) and path for output file**

local function kindLine(kinds, lines) -- find first line whose kind matches one of kinds in table
  for _, line in ipairs(lines) do for _, kind in ipairs(kinds) do if line.kind == kind then return line end end end
end

-- get docs directory in project for output files other than help files (which go with other environment help files)

local function mkdir(path) 
  if not path then error("codemark: mkdir: no path for directory") end
  if lfs.chdir(path) then return true end 
  return lfs.mkdir(path) 
end

local function directory(out, context) local outs = splitFiles(out);
  for i = 1, #outs - 1 do
    local dir = table.concat(outs, "/", 1, i); local path = absolutePath(dir, context)
    local ok, report = mkdir(path); if not ok then error("codemark.directory: "..report) end
  end; return absolutePath(table.concat(outs, "/", 1, 2), context) 
end 

local function docsGet(out, context) -- get absolute paths for output and configuration files
  local outPath, projectName = absolutePath(out, context), string.match(out, "(.-)/"); 
  local configPath = directory(out, context); return outPath, configPath, projectName
end

local function getProject(lines, context) -- project name, output path. and help path (for help files) to `codemarkCLI`
  local found = kindLine({"api", "list", "help"}, lines); 
  if not found then error("codemark.getProject: No file mark found in "..context) end
  local helpFile = found.kind == "help" and found.sign; 
  local HelpPath = helpFile and absolutePath(helpFile, context)
  local outPath, configPath, projectName = docsGet(found.out, context)
  local configured = loadfile(configPath.."/..zbs.api") -- non default project name for the ZBS api file
---@diagnostic disable-next-line: need-check-nil
  local api = not configured and projectName or configured().api 
  return api, outPath, HelpPath -- HelpPath only for help files
end

-- **Make a table of parsed code mark lines with their attributes: kind, line, sign, out and stripped text**
-- _Special handling for more or head: text set from sign_

local comments = {more = true, head = true, word = true}

local function markLine(this, inputPath)
  local mark, rest = string.match(this, markSplit) -- look for code marks
  if mark then local kind = marks[mark]; -- figure out the kind of the line
    if not kind then error("codemark.markline: Unrecognized "..mark.." for kind in "..this.." for "..inputPath, 0) end
    local sign, text, out = string.match(rest, splits[kind]); text = text or "" -- and split it accordingly
    if comments[kind] then text = sign or ""; sign = sign or "" end -- **special handling**: text from sign
    if not sign then error("Missing sign in marked comment "..this.." for "..inputPath) end
    local thisLine, thisSign, thisText = this, sign.." ", stripFormat(text)
    return {kind = kind, line = thisLine, sign = thisSign, text = thisText, out = out} 
  end; 
end

local function markLines(inputPath) -- make table of lines with their attributes
  local lines = {}; for this in io.lines(inputPath) do lines[#lines + 1] = markLine(this, inputPath) end
  return lines
end

-- **Update ZPS api table (loaded from ZBS api file) with ZBS handlers for each kind of input line**
-- _Accumulate Descriptions from MORE entries for help files and ZBS api entries_

-- **NOTE: Local variables holding mutated values during operations**

local ZBSapi, HelpPath, Descriptions, CurrentEntry, Checkings, Library = {}, nil, {}, nil, {}, ""

local function doKey(this) -- _ZBS api entry for word, face, cli: save record in ZBSapi for copy retrieval_
  local thisKey = string.match(this.sign, "(.-)%s"); local under = underWord(thisKey); ZBSapi[under] = this 
end

local function doWord(this) 
  Descriptions[#Descriptions + 1] = "\n"..stripFormat(this.text); CurrentEntry = {}; doKey(this)
end

local function doHead(this) 
  Descriptions[#Descriptions + 1] = "\n"..stripFormat(this.text); CurrentEntry = {}
end

local function doCLI(this)
  Descriptions[#Descriptions + 1] = "\n\n"..stripFormat(this.sign).."\n"; doHead(this); doKey(this)
end

local function doLib(this) -- make `lib` entries for module
  local moduleName, text = string.match(this.sign, "(.-)%s"), this.text
  local moduleLibs = string.match(this.text, "%->(.*)$") -- returns
  local description = "\n"..stripUnder(text); Descriptions = {description} --begin accumuluation
  local entry = {type = "lib", name = moduleName, description = description, returns = moduleLibs, kind = "module", childs = {} }
  ZBSapi[moduleName] = entry; CurrentEntry = entry; Library = moduleName
  for _, moduleLib in ipairs(commaSplit(moduleLibs)) do -- setup to get childs
    ZBSapi[moduleLib] = {type = "lib", name = moduleLib, childs = {}, returns = nil } -- not a module
  end
end -- _Create entry, return_ `nil`

local function makeName(sign)
  local first, second = firstWords(sign); 
  return second == "" and first or first.."."..second
end

local function makeChildKey(sign) -- return key, library
  local first, second = firstWords(sign); return (second == "" and first or second), (second ~= "" and first)
end

local function doFace(this) -- _Add a face as a child of a library, begin accumulation of face Descriptions_ 
  local description = "\n"..stripUnder(this.text); Descriptions = {description} --begin accumuluation
  local args, returns, name = parseSign(this.sign), (this.out or "").." <-\n", makeName(this.sign)
  local key, library = assert(makeChildKey(this.sign)); local ZBSlibrary = ZBSapi[library]; 
  if not ZBSlibrary then error("codemark.doFace: unknown library "..library.." for "..this.line) end
  local childs = ZBSlibrary.childs; local noOutline = string.find(name, "^_")
  local entry = {type = "function", name = name, args = args, description = description, returns = returns}
  childs[key] = entry; CurrentEntry = entry; ZBSapi["_"..name..":_"] = this -- for copy retrieval
  if name == "" then error() else return false, noOutline end
end

local function stripColon(this) return string.gsub(this, "(.-):?", "%1") end

local function doCopy(this) -- _Get output: retrieve line replacing saved sign with new text if any_ --, target, found
  local key, replacement = underWord(this.sign), stripColon(stripFormat(this.text)) -- just underscore pair in key
  local saved = ZBSapi[key]; if not saved then return end
  if saved.kind ~= "face" then return saved end
  local target = makeName(saved.sign) -- if kind is face generate new sign and line from saved
  local line = string.gsub(saved.line, target, replacement)
  local sign = string.gsub(saved.sign, target, replacement)
  return {kind = saved.kind, text = saved.text, out = saved.out, line = line, sign = sign} 
end

local function doMore(this) Descriptions[#Descriptions + 1] = stripUnder(this.text) end -- _accumulate till there's no_ `MORE`

local function doType(this) -- _Setup to begin accumulation of type's Descriptions_
  local description = "\n"..stripUnder(this.text); Descriptions = {description} --begin accumuluation
  local returns, name = (this.out or ""), makeName(this.sign); local noOutline = string.find(name, "^_")
  local ZBSlibrary = ZBSapi[Library]; local childs = ZBSlibrary.childs -- the table of library (inter)faces
  local entry = {type = "value", returns = returns, description = description, name = name}
  childs[":"..name] = entry; return false, noOutline
end

---@diagnostic disable-next-line: cast-local-type
local function skip() Library = nil end -- nothing to handle for api, help, and list file marks

local ZBShandlers = { -- dispatch according to kind; only the copy handler returns other than `nil`
  api = skip, help = skip, list = skip, head = doHead, word = doWord, cli = doCLI, copy = doCopy, 
  lib = doLib, face = doFace, more = doMore, type = doType, 
}

-- **Make outLines table for output, dispatch to ZBS handlers to update ZBS api file**

local spacers = {api = "", list = "", help = "", head = "\n\n", type = "\n\n", face = "\n\n", word = "\n\n", cli = "\n\n"} 

local function stripLink(text) return string.gsub(text, '%[(.-)%]%(.-%)', '%1') end

local function finishClump(helpLines) -- no MORE to process
---@diagnostic disable-next-line: inject-field
  CurrentEntry.description = table.concat(Descriptions, " "); 
---@diagnostic disable-next-line: need-check-nil
  helpLines[#helpLines + 1] = stripLink(CurrentEntry.description).."\n"
  Descriptions = {}; CurrentEntry = nil
end

local function markPart(text) return "--:"..string.match(text or "", "%-%-:(.*)") end -- from the mark to the line end

local function doDone(this) return (spacers[this.kind] or "  \n")..markPart(this.line).."  " end

local function doRedo(result) ZBShandlers[result.kind](result) return doDone(result) end -- copy template creates face

local function doLines(marked) -- process marked input lines
  local outLines, helpLines = {}, {}; for _, this in ipairs(marked) do -- make outLines table, update ZBSapi table
    if this.kind ~= "more" and CurrentEntry then finishClump(helpLines) -- `more` for `type`, `face`, or `lib`
    end; local result, noOutLine = ZBShandlers[this.kind](this) -- copy handler returns result, else just use line text
    if not noOutLine then outLines[#outLines + 1] = (result and doRedo(result) or doDone(this)) end
  end; if CurrentEntry then finishClump(helpLines) end
  return outLines, helpLines
end

local function testLine(line)
  ZBSapi = {}; Library = "TEST"; ZBSapi[Library] = {}; ZBSapi[Library].childs = {}
  local markedLine = markLine(line); ZBShandlers[markedLine.kind](markedLine) 
  return ZBSapi
end

-- **Get project and output file handles, process input file, write it all out** 

local function serializes (o, file) -- adapted from https://www.lua.org/pil/12.1.1.html
  if type(o) == "number" then file:write(o)
  elseif type(o) == "string" then file:write(string.format("%q", o))
  elseif type(o) == "table" then file:write("{\n")
    for k,v in pairs(o) do 
      file:write("  ["); serializes(k, file); file:write("] = "); serializes(v, file); file:write(",\n")
    end; file:write("}\n")
  else error("codemark.serializes: Failed for "..type(o))
  end
end

local function serialize(o, file) file:write("return "); serializes(o, file) end

local function output(outLines, file) for _, line in ipairs(outLines) do assert(file:write(line)) end end

local function getZBSapi(ZBSapiFile) local loaded = loadfile(ZBSapiFile); return loaded and loaded() or {}; end

local function codemarkCLI(input, ZBSroot, apiPath) -- ZBSroot if called from ZBS package, apiPath if called from CLI
  ZBSapi, HelpPath, Descriptions, CurrentEntry, Checkings = {}, nil, {}, nil, {}-- initialize
  local marked = markLines(input); 
  local project, outPath, HelpPath = getProject(marked, input); 
  local ZBSapiPath = project and ZBSroot and ZBSroot.."api/lua/"..project..".lua"
  local apiLoad = apiPath and loadfile(apiPath); -- either ZBSroot or existing apiFile or {}
  ZBSapi = (ZBSapiPath and getZBSapi(ZBSapiPath)) or (apiLoad and apiLoad() or {})
  local outLines, helpLines = doLines(marked); -- **do the work**
  local handleZ = assert(io.open(apiPath or ZBSapiPath, "w")); serialize(ZBSapi, handleZ); assert(io.close(handleZ))
  local handleO = assert(io.open(outPath, "w")); output(outLines, handleO); handleO:flush(); assert(io.close(handleO))
  if HelpPath then local handleH = assert(io.open(HelpPath, "w")); output(helpLines, handleH); assert(io.close(handleH)) end
  return Checkings, #outLines, outPath, HelpPath, ZBSapiPath or apiPath
end

local marker = function() -- not used by markFiles
---@diagnostic disable-next-line: undefined-global
  local ed, ZBSroot= ide:GetEditor(), ide:GetRootPath()
---@diagnostic disable-next-line: undefined-global
  local fileEdited = ide:GetDocument(ed):GetFilePath()
  local marked, Checkings, lines, outPath, HelpPath, apiPath = pcall(codemarkCLI, fileEdited, ZBSroot)
  if not marked then ide:Print("CodeMark File?: "..lines.." for "..fileEdited) end
  for _, checking in ipairs(Checkings) do ide:Print(checking) end
  if apiPath then ide:Print("Updating "..apiPath) end
  if outPath then ide:Print(lines.." lines output to "..outPath) end
  if HelpPath then ide:Print("help file is "..HelpPath) end
end

return {
  name = "CodeMark Plugin",
  description = "Documentation generator for currently edited file",
  author = "Minerbadd",
  version = 0.01,
  onRegister = function(self)
---@diagnostic disable-next-line: undefined-global
    local id = ID("codemark.codemark")
    local menu = ide:FindTopMenu("&Project")
    menu:Append(id, "CodeMark\tCtrl-M")
---@diagnostic disable-next-line: undefined-global
    ide:GetMainFrame():Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED, marker)
---@diagnostic disable-next-line: undefined-global
    ide:GetMainFrame():Connect(id, wx.wxEVT_UPDATE_UI, function(event)
        event:Enable(ide:GetEditor() ~= nil)
      end)
  end,

  onUnRegister = function(self)
---@diagnostic disable-next-line: undefined-global
    local id = ID("codemark.codemark")
    ide:RemoveMenuItem(id)
  end,

  cli = codemarkCLI, -- **Interface for (bulk) Command Line Interface (and to assist debug)**
  line = testLine
}

