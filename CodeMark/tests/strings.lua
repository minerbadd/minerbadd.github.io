
local function firstWords(text) 
  local name = string.match(text, "(.-)[:%(%s]"); if not name then return "" end
  return string.match(name, "([%a%d_]+).?(%a*%d*)") 
end 

firstWords("a ")

local function commaSplit(text)
  local items = {}; items[#items + 1] = string.match(text, "([^,]*),?"); -- first
  for item in string.gmatch(text, ",([^,]*)") do items[#items + 1] = item end
  return items
end

commaSplit("aaa, bbb, ccc")
--[[
local function parseSign(sign) -- function name including library ends before ( or [ or {, signature follows and the rest
  local name, signaturePart = string.match(sign, "(.-)(%b())")
  local signature = string.match(signaturePart, "^%((.-)%)$")
  return signature, name
end

parseSign("field.plot(commands: field.plotSpan, fieldsOp: (:), fieldOpName: \":\", plots: #:, offset: xyz?)  ")


local strippers =  {"(%?)%?*", "`(.-)`", "(.-)<%-", "(.-)&(.*)",  "(.-)\n", "(%?)%?-"}

local function stripOther(text, index)
  if index > #strippers then return text end
  local stripped = string.gsub(text, strippers[index], "%1")
  return stripOther(stripped, index + 1)
end

stripOther("vectors: xyzMap, face: \":\"?, rotate: \":\"??  ", 1)

-- **Partition text keeping containers whole**

local containers = { -- ordered for funContainer, groupContainer, tableContainer, tupleContainer
  {"%b():", "%(.-%):.-$"}, {"%b()", "%b()"}, {"%b{}", "%b{}"}, {"%b[]", "%b[]"},
}

local function semicommas(target) local replaced = string.gsub(target, ",", ";") return replaced end

local function hide(target, replacing) -- replacing function
  return function(text) return string.gsub(text, target, replacing) end
end

local function protect(text)
  for _, container in ipairs(containers) do
    local finder, target = table.unpack(container)
    local found = string.find(text, finder)
    if found then return string.gsub(text, target, hide(target, semicommas)) end
  end
end

local function partition(pattern) -- iterator factory
  return function(text) -- handle single and last parts
    local position, length = 1, string.len(text)
    return function() -- first > last is `string.find` workaround
      if position > length then return end -- terminate iterator
      local first, last = string.find(text, pattern, position)
      local ending = (first and first < last) and last  or length + 1
      local part = string.sub(text, position, ending - 1); position = ending + 1
      return part
    end
  end
end

local function restore(text) -- create table of restored parts
  local parts = {}; for part in partition("([^,]-),")(text) do
    parts[#parts + 1]  = string.gsub(part, ";", ",") -- within part
  end
  return parts
end

local testTexts = {
  'commands: [command: ":", location: ":", yD: #:?], fill: ":"?, targets: ":"[]?', 
  "commands: [command: \":\", direction: facing]_  ",
  '{command: ":"[] }  ',
  'arguments: task.puts, op: (:), clear: ^:, fill: ":"?, targets: ":"[]?` ',
  ' commands: [op: ":", arguments: ":"[] ] ',
  ' [direction: ":", distance: #:, puttings: ":"[] ]',
  '{name: ":", down: downplan, back: moveplan, lower: moveplan, higher: moveplan}',
  ' {[opName]: xyz}',
  ' #:[], #:[], eP, eP, striding, ^:, ^: ',
  ' (dx: #:, dz: #:): cardinal: ":"',
  ' {[":"]: ::}',
  ' {x: #:, y: #:, z: #:}',
}
for i, testText in ipairs(testTexts) do 
  local parts = restore(protect(testText))
  local result = table.concat(parts, ", ")
  print(i, result)
end

--[[
  local t1 = string.gsub(":xyz:", ":([_%a%d]-):", "%1: %1")

  print(t1)


local function stripSpaces(text)
  local unSpaced = string.gsub(text, "%s*(%w-)%s*", "%1")
  return unSpaced
end

stripSpaces("aa    _bb_    cc")

local function stripReturns(text)
  local noArrow = string.gsub(text, "(.-)<%-", "%1")
  local noExceptions = string.gsub(noArrow, "(.-)&(.-)$", "%1")
  return noExceptions
end

stripReturns(" cardinal: \":\"")
--stripReturns("(): `name: \":\", label: \":\", xyz, distance: #:, situations, serialized: \":\" &:` <-\n")

--]]