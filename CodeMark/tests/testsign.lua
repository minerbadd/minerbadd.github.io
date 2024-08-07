-- **Tests for signfiles entry**

local executionDirectory = arg[0]:match('.*[/\\]') -- get execution directory

local function splitFiles(path)   -- make a table split by \ or /
  local files = {}; for name in string.gmatch(path, "([^/\\]+)[/\\]?") do table.insert(files, name) end 
  return files
end

local files = splitFiles(executionDirectory); 
local CodeMark =  table.concat(files, "/", 1, #files - 1).."/"
local signfiles = dofile(CodeMark.."signfiles.lua")

local testData = {

{
  ["type"] = "value",
  ["returns"] = " `[role]: \":\"|#:`",
  ["name"] = "IDs",
  ["description"] = "Dictionary of strings or numbers keyed by MUSE role",
},
{
  ["type"] = "value",
  ["returns"] = " (\":\"|#:)[]",
  ["name"] = "IDs",
  ["description"] = "Array of groups of strings or numbers",
},
{
  ["returns"] = " `^:, \":\", #: &:` <-",
  ["args"] = "arguments: :[op: \":\", placeName: \":\", borePlansFileOrLevels: \":\"|#:, shaftPlansFile: \":\"]",
  ["type"] = "function",
  ["name"] = "mine.op",
  ["description"] = "Dig. Dig shaft; go to post at level; bore, mark, and torch; get ores. Markers hold saved plans.",
},
{
  ["type"] = "value",
  ["returns"] = " `xyz[] | [core.faces]: xyz`",
  ["name"] = "xyzMap",
  ["description"] = "Table of vectors either an array or dictionary",
},
{
  ["returns"] = " `[port.item]: #:` <-",
  ["args"] = "set: [port.item]: #:",
  ["type"] = "function",
  ["name"] = "port.available",
  ["description"] = "For Testing: mock player inventory",
},
{
  ["returns"] = " `nil`  <-",
  ["args"] = "turtle: \":\", __: \"tail\", rate: #:?",
  ["type"] = "function",
  ["name"] = "remote.tail",
  ["description"] = "Repeatedly towards player position, default rate 0.5 seconds.",
},
{
  ["returns"] = " `^:, \":\", #: &:` <-",
  ["args"] = "arguments: :[op: \":\", placeName: \":\", borePlansFileOrLevels: \":\"|#:, shaftPlansFile: \":\"]",
  ["type"] = "function",
  ["name"] = "mine.op",
  ["description"] = "Dig. Dig shaft; go to post at level; bore, mark, and torch; get ores. Markers hold saved plans.",
},
{
  ["returns"] = " `#:[], #:[], eP, eP, striding, ^:, ^:` <-",
  ["args"] = ":bounds:, :strides:, faced: \":\"?",
  ["type"] = "function",
  ["name"] = "field.extents",
  ["description"] = "Plots placed Returns `nplots:#:[], slots:#:[], strides: eP, run: eP, striding, turn: ^:, back: ^: Extents for `stride` (shorter) and `run` (longer) virtual axes for each `opName` in the `strides` entries unless `faced`.",
},
{
  ["type"] = "value",
  ["returns"] = " `(value: any): value: any`",
  ["name"] = "closing",
  ["description"] = "Returns value or sets it and optional table entry to non `nil` `value`.",
},
{
  ["returns"] = " `report: \":\" &: &!` <-",
  ["args"] = "commands: field.plotSpan, fieldsOp: (:), fieldOpName: \":\", plots: #:, offset: xyz?",
  ["type"] = "function",
  ["name"] = "field.plot",
  ["description"] = "Plots Called by field files. Calls `fieldsOp` from field file (which calls `field.plan`).",
},
{
  ["returns"] = " \":\" &! <-",
  ["args"] = "arguments: task.puts, op: (:), clear: ^:, fill: \":\"?, targets: \":\"[]?",
  ["type"] = "function",
  ["name"] = "_task.doTask",
  ["description"] = "Tasks",
},
{
  ["type"] = "value",
  ["returns"] = " `:[ look: grid.cut, dig: grid.cut[], lookMore: grid.cut, digMore: grid.cut[] ]`",
  ["name"] = "grid.guide",
  ["description"] = "Instructions for cut",
},
{
  ["type"] = "value",
  ["returns"] = " `{[key: \":\"]: ::}`",
  ["name"] = "features",
  ["description"] = "Dictionary of string key, any value pairs",
},
{
  ["returns"] = " `{distance: #:, name: \":\", label: \":\", cardinal: \":\", xyzf}` <-",
  ["args"] = ":xyzf:?, :cardinals:",
  ["type"] = "function",
  ["name"] = "place.nearby",
  ["description"] = "Sorted",
},
{
  ["type"] = "value",
  ["returns"] = " `{:bores:, ores: {name: \":\", fixtures: \":\"[], path: \":\"[], work: plan.work} }`",
  ["name"] = "crossplan",
  ["description"] = "Bore and mine, minimal movement",
},
{
    ["returns"] = " `^:, \":\", #: &:` <- ",
    ["args"] = "arguments: [op: \":\", placeName: \":\", borePlansFileOrLevels: \":\"|#:, shaftPlansFile: \":\"]",
    ["type"] = "function",
    ["name"] = "mine.op",
    ["description"] = "Dig. Dig shaft; go to post at level; bore, mark, and torch; get ores. Markers hold saved plans.",
  },
  {
    ["returns"] = " `xyz, xyz, #:, #:` <-",
    ["args"] = "nearPlace: \":\", farPlace: \":\"`  ",
    ["type"] = "function",
    ["name"] = "_field.makeBounds",
    ["description"] = "Get coordinate pair for named places.",
  },
  {
    ["returns"] = " `\":\" &:` <-",
    ["args"] = "commandLine: [command: \":\", ...: \":\"]  ",
    ["type"] = "function",
    ["name"] = "exec.op",
    ["description"] = "CLI for Command Computer commands",
  },
  {
    ["type"] = "value",
    ["returns"] = " `{[some: role]: #:}`",
    ["name"] = "IDs",
    ["description"] = "Dictionary of Computercraft computer IDs keyed by MUSE role",
  },
  {
    ["returns"] = " `xyzMap` <-",
    ["args"] = "vectors: xyzMap, face: \":\"?, rotate: \":\"??  ",
    ["type"] = "function",
    ["name"] = "core.orient",
    ["description"] = "Three dimensional rotation Turn from up north to face, default for no face is to rotate -90 degrees.",
  },
  {
    ["returns"] = " `{:}|::` <-",
    ["args"] = "source: {:}|::  ",
    ["type"] = "function",
    ["name"] = "core.clone",
    ["description"] = "Deep copy source table or return source if not table.",
  },
  {
    ["returns"] = " `(:)` <-",
    ["args"] = "completions: {:}  ",
    ["type"] = "function",
    ["name"] = "core.completer",
    ["description"] = "Register command completions for shell",
  },
  {
    ["returns"] = " `(:), {:}, #:` <-",
    ["args"] = "table: {:}, index: #:  ",
    ["type"] = "function",
    ["name"] = "core.inext",
    ["description"] = "Iterator over table beginning at index.",
  },
  {
    ["returns"] = " `closing` <-",
    ["args"] = "table: {:}?, key: \":\"?  ",
    ["type"] = "function",
    ["name"] = "core.state",
    ["description"] = "Returns closure over closure variable",
  },
  {
    ["type"] = "value",
    ["returns"] = " `[xyz, xyz]`",
    ["name"] = "bounds",
    ["description"] = "Vector pair defining a rectangular solid",
  },
  {
    ["returns"] = " ok: `true|false, result: ...|\":\", ::?` <-",
    ["args"] = "ok: ^:, ...: ::  ",
    ["type"] = "function",
    ["name"] = "core.pass",
    ["description"] = "Pass input but report string if not ok.",
  },
  {  
    ["returns"] = " `\"return \"..\":\" &!` <-",  
    ["args"] = "input: ::  ",
    ["type"] = "function",
    ["name"] = "core.serialize",
    ["description"] = "Executable string to instantiate input.",
  },
  {
    ["type"] = "value",
    ["returns"] = " `{even: plan, odd: plan}`",
    ["name"] = "moveplan",
    ["description"] = "Traverse (and fill shelves for  player safety in back plan) shaft",
  },
  {
    ["type"] = "value",
    ["returns"] = " `{name: detail.name, count: detail.count, damage: detail.damage}`",
    ["name"] = "detail",
    ["description"] = "Defined by Computercraft",
  },
  {
    ["returns"] = " `report: \":\" &:` ",
    ["args"] = "commands: \":\"[]}  ",
    ["type"] = "function",
    ["name"] = "map.op",
    ["description"] = "Command Line Interface",
  },

  {
    ["returns"] =  ' \":\" ',
    ["args"] = "(commands: [command: \":\", direction: facing])_  ",
    ["type"] = "function",
    ["name"] = "_gps.equip",
    ["description"] = "Assemble parts.",
  },

  {
    ["returns"] = " `(): \"done\", remaining: #:, xyzf, direction &!recovery` <-",
    ["args"] = ":(count: #:?)  ",
    ["type"] = "function",
    ["name"] = "step.left",
    ["description"] = "Iterator (default 1 step)",
  },

  {
    ["returns"] = " (): `name: \":\", label: \":\", xyz, distance: #:, situations, serialized: \":\"` <-" ,
    ["args"] = "(span: #:?, reference: \":\"?|position?)  ",
    ["type"] = "function",
    ["name"] = "place.near",
    ["description"] = "If both the span and name or position are specified, return places within a span of blocks of the named place or position. If only the span is specified, return places within a span of blocks of the current situation or player position. If neither is specified return each of the named places. In any case, iterator returns include serialized places.",
  },
  {
    ["args"] = "(commandLine: \":\", bogus: ((foo: #:): ^:, #:), scam: (mum: ^:): (:), {:})  ",
    ["type"] = "function",
    ["name"] = "exec.fakeop",
    ["description"] = "CLI for Command Computer commands",
  },

}

for i, item in ipairs(testData) do 
  local result = signfiles.test(item)
  print(i, result)
end


