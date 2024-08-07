-- **Produce function to generate HTML file from very limited, special purpose `markdown` file**
local downMark = {}

---@diagnostic disable-next-line: undefined-field
require("lfs"); local lfs = _G.lfs -- to surpress lint warnings

-- Constants first, keep code tight

local luaHeader = [[
<!DOCTYPE html> 
  <html> 
  <head> 
  <link href="../../assets/prism.css" rel="stylesheet" /> 
  <link href="../../assets/muse.css" rel="stylesheet" /> 
  </head> 
  <body> 
     <script src="../../assets/prism.js"></script> 
]]

local markdownHeader = [[
<!DOCTYPE html> 
  <html> 
    <head> 
      <link href="../../assets/museMD.css" rel="stylesheet" /> 
    </head> 
  <body> 
    <pre>
]]

local luaFooter = [[
  </body> 
</html>
]]

local markdownFooter = [[
    </pre>
  </body> 
</html>
]]

local header = {lua = luaHeader, md = markdownHeader}
local footer = {lua = luaFooter, md = markdownFooter}

local hashBase = 3 -- maximum <h..> .. </h..>
local inScript = false

local matches = {
  {"%*%*(.-)%*%*", "<b>%1</b>"}, -- bold
  {'"_','"@@'}, -- `target="_blank"`
  {"_:",":@@"}, -- ignored signature
  {"__","@@"}, -- escaped _ in hrefs
  {"_,", "@@,"},-- ignored variable
  {"_G%.","@@G%."}, -- global
  {"`_(%w*)","`@@%1"}, -- internal sign
  {"_(.-)_","<i>%1</i>"}, -- italics
  {"%*(.-)%*", "<i>%1</i>"}, --alternate italics
  {"@@", "_"}, -- restoration
  {"`(.-)`", "<code>%1</code>"}, -- code
  {'%[(.-)%]%((.-)%)', '<a href="%2">%1</a>'}, -- link
}

local function lineHTML (inLine)  
  for _, match in ipairs(matches) do local found, swap = table.unpack(match)
    inLine = string.gsub(inLine, found, swap);
  end; return inLine
end

local function sectionLine (inLine)   -- Check for section header markup and produce <h...>.
  local hashes, rest = string.match(inLine, "^(#+)(.-)$")
  local hashCount = hashes and string.len(hashes) or 0; if hashCount == 0 then return inLine end
  local sectionLevel = hashBase - hashCount + 1
  local outLine = "<h"..sectionLevel..">"..rest.."</h"..sectionLevel..">"
  return outLine
end

local function blankLine (inLine)
  if inScript then return end
  local something = string.match(inLine, "(%S)" )
  return not something and "<p>"
end

local function scanLine (line) 
  local blank, html = blankLine(line), lineHTML(line); local section = sectionLine(html)
  return blank or section
end

downMark.test = scanLine

local mdCode = '<pre><code class="language-markdown">'
local luaCode = '<pre><code class="language-lua">'
local endCode = "</code></pre>"

local finds = {
  {"```[Ll]ua", function (out) if inScript then out[#out + 1] = endCode end; out[#out + 1] = luaCode; inScript = true end}, 
  {"```md", function (out) if inScript then out[#out + 1] = endCode end; out[#out + 1] = mdCode; inScript = true end}, 
  {"<pre>", function (out, line) inScript = true; out[#out + 1] = line end},
  {"</pre>", function (out, line) inScript = false; out[#out + 1] = line end},
  {"```",  function (out) inScript = false; out[#out + 1] = endCode end},
  {"%-%-%[%[", function() end}, {"%-%-%]%]", function() end}, -- eliminate comment block delimiters
}

local function checkLine(line, out) -- special line?
  for _, find in ipairs(finds) do local check, op = table.unpack(find)
    if string.find(line, check) then op(out, line); return end 
  end; out[#out + 1] = scanLine(line) -- no special lines
end

local function putHTML (inLines, outLines) -- produce table of HTML lines from limited markup 
  for line in inLines:gmatch("([^\n]*)\n?") do checkLine(line, outLines)  end
end

local function writeLines (outLines, fileOut, outHTML, verbose) 
  for _, line in ipairs(outLines) do fileOut:write(line, "\n") end 
  if verbose then print(#outLines.." lines written in "..outHTML) end
end

local function makeOut(outName)
  local files = {}; for name in string.gmatch(outName, "([^/\\]+)[/\\]?") do table.insert(files, name) end
  local directory = table.concat(files, "/", 1, #files - 1).."/"   -- separate directory and fileName
  local realized = lfs.chdir(directory) and directory or lfs.mkdir(directory) -- realize directory
  if realized then realized = directory end -- very odd workaround 
  if not realized or type(realized) == "boolean" then -- in spite of workaround
    print("downMark.makeOut: retry directory failure for "..outName)
  end
  assert(realized, "downMark.makeOut: can't make directory "..directory.." for "..outName)
  local _, _, outStub = string.find(files[#files], "(.*)%.(.*)$")
  return realized..outStub..".html" -- replace fileName extension with `html`
end

function downMark.cli (inPath, outPath, extension, verbose)
  local outHTML = makeOut(outPath) -- `outName` needs a realized directory and a proper (HTML) extension
  local fileIn, fileOut = assert(io.open(inPath, "r")), assert(io.open(outHTML, "w"))
  local outLines, inLines = {}, fileIn:read("*all"); fileIn:close()
  for line in header[extension]:gmatch("([^\n]*)\n?") do outLines[#outLines + 1] = line end
  inScript = extension == "md"; putHTML(inLines, outLines)-- put HTML lines in table
  for line in footer[extension]:gmatch("([^\n]*)\n?") do outLines[#outLines + 1] = line end
  writeLines(outLines, fileOut, outHTML, verbose); fileOut:flush(); fileOut:close()
end

return downMark
