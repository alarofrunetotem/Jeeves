local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title("Jeeves","RELNOTES")
self:HF_Paragraph("Description")
self:HF_Pre([[
Jeeves assists you in dressing

Whenever you acquire a new item suitable to upgrade your current equipment,  J
eeves proposes you a quick button to wear it
You can customize button appearance and minimu item quality

]])
self:RelNotes(1,0,0,[[
Initial release
]])

end

