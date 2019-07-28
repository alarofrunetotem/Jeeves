local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title("Jeeves","RELNOTES")
self:HF_Paragraph("Description")
self:HF_Pre([[
Jeeves assists you in dressing

Whenever you acquire a new item suitable to upgrade your current equipment,
Jeeves proposes you a quick button to wear it.
If you are an enchanter, shift-clicking the button will disenchant the item
You can customize button appearance and minimum item quality and level under which items are ignored
Jeeves also helps you in choosing quest rewards by preselecting the best selling item and graying out
ones not your armor class.
Note, I recommend OneChoice to improve you quest reward selection experience

]])
self:RelNotes(1,4,7,[[
Toc: 8.2.0
]])
self:RelNotes(1,4,3,[[
Toc: 7.3.0
]])
self:RelNotes(1,4,2,[[
Toc: 7.1.0
Feature: Improved armor class recognition
]])
self:RelNotes(1,2,0,[[
Feature: Considers also item directly pushed in inventory (like Missions rewards)
]])
self:RelNotes(1,1,1,[[
Fix: Quest rewards are now correctly proposed even if quest has only one choice
]])
self:RelNotes(1,0,1,[[
Fix: Quest rewards are now correctly grayed out
]])
self:RelNotes(1,0,0,[[
Initial release
]])
end

