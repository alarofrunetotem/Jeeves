---@diagnostic disable-next-line: undefined-field
local __FILE__=tostring(debugstack(1,2,0):match("(.*):2:")) -- MUST BE LINE 2
local toc=select(4,GetBuildInfo())
local me, ns = ...
local version,build,releaseDate,toc=GetBuildInfo()
local pp=print
--@debug@
C_AddOns.LoadAddOn("Blizzard_DebugTools")
C_AddOns.LoadAddOn("LibDebug")
---@diagnostic disable-next-line: undefined-global
if LibDebug then LibDebug() ns.print=print end
--@end-debug@
--[===[@non-debug@
ns.print=function() end
pp=ns.print
--@end-non-debug@]===]
local addon --#Jeeves
addon=LibStub("LibInit"):NewAddon(ns,me,'AceHook-3.0','AceEvent-3.0','AceTimer-3.0')
local L=addon:GetLocale()
local C=addon:GetColorTable()
local print=ns.print or print
local debug=ns.debug or print
----------------------------------------------
-- Library loading
--
local D=LibStub("LibDeformat-3.0")
local I=LibStub("LibItemUpgradeInfo-1.0")
----------------------------------------------
-- upvalues
local _G=_G
local setmetatable=setmetatable
local next=next
local pairs=pairs
local wipe=wipe
local format=format
local GetTime=GetTime
local strjoin=strjoin
local strspilit=strsplit
local tostringall=tostringall
local tostring=tostring
local tonumber=tonumber
local type=type
local SetItemButtonTexture= SetItemButtonTexture
local SetItemButtonCount=SetItemButtonCount
local GetItemInfo=function(a,b) end
local GetQuestItemLink=GetQuestItemLink
local GetMerchantItemLink=GetMerchantItemLink
local GetContainerNumSlots=C_Container.GetContainerNumSlots
local GetContainerItemID=C_Container.GetContainerItemID
local PickupContainerItem=C_Container.PickupContainerItem
local ToggleCharacter=ToggleCharacter
local GameTooltip_ShowCompareItem=GameTooltip_ShowCompareItem
local GameTooltip=GameTooltip
local CharacterFrame=CharacterFrame
local CursorUpdate=CursorUpdate
local ResetCursor=ResetCursor
local CreateFrame=CreateFrame
local LOOT_ITEM_SELF=LOOT_ITEM_SELF
local GetItemQualityColor=C_Item.GetItemQualityColor
local QuestDifficultyColors=QuestDifficultyColors
local GetInventoryItemLink=GetInventoryItemLink
local GetNumQuestChoices=GetNumQuestChoices
local QuestInfoItem_OnClick=QuestInfoItem_OnClick
local SetItemButtonTextureVertexColor=SetItemButtonTextureVertexColor
local SetItemButtonNameFrameVertexColor=SetItemButtonNameFrameVertexColor
local SetItemButtonDesaturated=SetItemButtonDesaturated
local GetAverageItemLevel=GetAverageItemLevel
local InCombatLockdown=InCombatLockdown
local tinsert=tinsert
local tremove=tremove
-----------------------------------------------------------------
--local data
local leatherSkill=76273
local mailSkill=76250
local lastitem
local jeeves
local average=0
local OneChoice
local armorClass=nil
local _G=_G
local autoitem=1
local wearqueue={}
local armorClasses= {
	["WARRIOR"] = Enum.ItemArmorSubclass.Plate,
	["PALADIN"] = Enum.ItemArmorSubclass.Plate,
	["HUNTER"] = Enum.ItemArmorSubclass.Mail,
	["ROGUE"] = Enum.ItemArmorSubclass.Leather,
	["PRIEST"] = Enum.ItemArmorSubclass.Cloth,
	["DEATHKNIGHT"] = Enum.ItemArmorSubclass.Plate,
	["SHAMAN"] = Enum.ItemArmorSubclass.Mail,
	["MAGE"] = Enum.ItemArmorSubclass.Cloth,
	["WARLOCK"] = Enum.ItemArmorSubclass.Cloth,
	["MONK"] = Enum.ItemArmorSubclass.Leather,
	["DRUID"] = Enum.ItemArmorSubclass.Leather,
	["DEMONHUNTER"] = Enum.ItemArmorSubclass.Mail,
};
local function push(itemlink)
	tinsert(wearqueue,itemlink)
end
local function pop()
	return tremove(wearqueue,1)
end
local function loc2slots(loc)
	local slot=loc:gsub('INVTYPE','INVSLOT')
	if (not _G[slot]) then
		if (slot=='INVSLOT_FINGER' or slot=='INVSLOT_TRINKET') then
			return _G[slot..'1'],_G[slot..'2']
		elseif (slot=='INVSLOT_WEAPON') then
			return INVSLOT_MAINHAND,INVSLOT_OFFHAND
		elseif  (slot=='INVSLOT_2HWEAPON' or slot=='INVSLOT_WEAPONMAINHAND') then
			return INVSLOT_MAINHAND
		elseif  (slot=='INVSLOT_HOLDABLE' or slot=='INVSLOT_WEAPONOFFHAND') then
			return INVSLOT_OFFHAND
		elseif  (slot=='INVSLOT_RANGED' or slot=='INVSLOT_THROWN') then
			return INVSLOT_RANGED
		elseif  (slot=='INVSLOT_ROBE' ) then
			return INVSLOT_CHEST
		elseif  (slot=='INVSLOT_CLOAK' ) then
			return INVSLOT_BACK
		end
	else
		return _G[slot]
	end
end
local slotTable=setmetatable({},{
	__index=function(table,key)
		local s1,s2=loc2slots(key)
		rawset(table,key,{s1=s1,s2=s2,double=s2})
		return table[key]
	end
})

--@debug@
function addon:test(item)
	item=tonumber(item)
	if (not item) then
		item=autoitem
		autoitem=autoitem+1
	end
	lastitem=GetInventoryItemLink("player",item)
	if (autoitem > INVSLOT_LAST_EQUIPPED) then
		autoitem=INVSLOT_FIRST_EQUIPPED
	end
	self:redo()
end
--@end-debug@
function addon:demo()
	lastitem=select(2,GetItemInfo(6256)) -- A nice fishing pole
	self:redo()
	lastitem=nil
end
function addon:redo()
  self:Print(lastitem)
	if (lastitem) then
		self:AskEquip(lastitem)
	end
end

function addon:CHAT_MSG_LOOT(evt,p1,...)
	local newLink=D.Deformat(p1,LOOT_ITEM_SELF)
	if not newLink then newLink=D.Deformat(p1,LOOT_ITEM_PUSHED_SELF) end
	if not newLink then newLink=p1:match("|Hitem.*|h") end
	if not newLink then return end
	local rc,name,itemlink,rarity,level,minlevel,type,subtype,count,loc,texture,price=pcall(GetItemInfo,newLink)
	--@debug@
	if (not rc) then
		pp(p1, "has not a valid itemlink:",newLink)
	else
		pp(p1, "got",newLink)
	end
	--@end-debug@
	if (loc and loc~='') then
---@diagnostic disable-next-line: param-type-mismatch
		if (C_Item.GetItemCount(itemlink)>0) then
--@debug@
			pp("Dropped equippable object ",name,loc,_G[loc])
--@end-debug@
			self:ScheduleTimer("AskEquip",0.2,itemlink)
		else
--@debug@
			pp("You dont have ",name)
--@end-debug@
		end
	end
end
function addon:UNIT_INVENTORY_CHANGED(event,unit)
	armorClass=nil
end
function addon:GetQuestReward(choice)
	if (not choice or choice==0) then choice=1 end
	local itemlink=GetQuestItemLink("choice",choice)
--@debug@
pp("Assegnato reward",itemlink, "from",choice)
--@end-debug@
	self:AskEquip(itemlink)
end
function addon:BuyMerchantItem(choice)
	local itemlink=GetMerchantItemLink(choice)
--@debug@
pp("Acquistato oggetto",itemlink)
--@end-debug@
	self:AskEquip(itemlink)
end
function addon:OnClick(this,button,opt)
--@debug@
pp("Clicked",button,opt)
--@end-debug@
	if (button=="LeftButton") then
		local autoWear= not ((slotTable[GetItemInfo(this.itemlink,9)]).double)
		if (autoWear) then
			--@debug@
			pp("EquipByName",this.itemlink)
			--@end-debug@
			C_Item.EquipItemByName(this.itemlink)
		else
			local foundid,bag,slot=self:ScanBags(0,addon:GetItemID(this.itemlink))
		--@debug@
print(foundid,bag,slot)
--@end-debug@
			if (bag and slot) then
				PickupContainerItem(bag,slot)
			--@debug@
print("Will equip ",this.iteminfo[1])
--@end-debug@
				if (not CharacterFrame:IsShown()) then
					ToggleCharacter("PaperDollFrame")
				end
			else
				self:Onscreen_Red(this.iteminfo[1] .. ': ' .. ERR_ITEM_NOT_FOUND)
			end
		end
	end
	jeeves:Hide()
	self:AskEquip()

end
function addon:ToolTip(this)
					GameTooltip:SetOwner(this, "ANCHOR_NONE");
					GameTooltip:SetPoint("TOPLEFT",this,"BOTTOMLEFT")
					GameTooltip:SetHyperlink(this.itemlink)
					GameTooltip:AddLine(KEY_BUTTON1 .. ': ' .. EQUIPSET_EQUIP,0,1,0)
					GameTooltip:AddLine(KEY_BUTTON2 .. ': ' .. CLOSE)
					GameTooltip:Show()
					GameTooltip_ShowCompareItem(GameTooltip);
					CursorUpdate(this);
end
function addon:AskEquip(itemlink)
	if (not itemlink) then
		itemlink=pop()
	end
	if (not itemlink) then return end
--@debug@
	pp("AskEquip",itemlink)
--@end-debug@
	average=GetAverageItemLevel()
	if (C_Item.IsEquippableItem(itemlink) and GetItemInfo(itemlink,3) >= self:GetNumber('MINQUAL') and self:ValidArmorClass(itemlink)) then
		local perc=self:Compare(I:GetUpgradedItemLevel(itemlink),GetItemInfo(itemlink,9))
		if (perc<self:GetNumber('MINLEVEL')) then
			--@debug@
			pp(itemlink,"failed perc",perc,I:GetUpgradedItemLevel(itemlink))
			--@end-debug@
			return
		end
		lastitem=itemlink
		push(itemlink)
		if (InCombatLockdown()) then
			self:ScheduleLeaveCombatAction('ShowEquipRequest')
		else
			self:ScheduleTimer('ShowEquipRequest',1)
		end
	end
end
function addon:APPLY(...)
--@debug@
print("Apply",...)
--@end-debug@
end
---@diagnostic disable-next-line: undefined-field
local AlertFrame_AnimateIn=_G.AlertFrame_AnimateIn
if not AlertFrame_AnimateIn then
-- Legion change
	function AlertFrame_AnimateIn(frame)

		frame:Show();
		frame.animIn:Play();
		if frame.glow then
			if frame.glow.suppressGlow then
				frame.glow:Hide();
			else
				frame.glow:Show();
				frame.glow.animIn:Play();
			end
		end

		if frame.shine then
			frame.shine:Show();
			frame.shine.animIn:Play();
		end
		frame.waitAndAnimOut:Stop();	--Just in case it's already animating out, but we want to reinstate it.
		if frame:IsMouseOver() then
			frame.waitAndAnimOut.animOut:SetStartDelay(1);
		else
			frame.waitAndAnimOut.animOut:SetStartDelay(4.05);
			frame.waitAndAnimOut:Play();
		end
	end
end
function addon:ShowEquipRequest(itemlink)
	if (not jeeves) then
			jeeves=JeevesFrame
			--[[
			jeeves:SetPoint("CENTER",UIParent,"CENTER",0,300)
			jeeves:RegisterForClicks("AnyUp")
			jeeves:RegisterForDrag("LeftButton")
			jeeves:SetMovable(true)
			jeeves:SetClampedToScreen(true)
			jeeves:SetScript("OnDragStart",function(self,...) self:StartMoving() end)
			jeeves:SetScript("OnDragStop",function(self,...) self:StopMovingOrSizing()end)
			jeeves:SetScript("OnLeave",function() GameTooltip:Hide() ResetCursor() end)
			--]]
			jeeves:SetScript("OnClick",function(...) addon:OnClick(...) end)
			jeeves:SetScript("OnEnter",function(...) addon:ToolTip(...) end)
	end
	if (not itemlink) then itemlink=pop() end
	if (not itemlink) then return end
	local level=I:GetUpgradedItemLevel(itemlink)
	jeeves.itemlink=itemlink
	jeeves.iteminfo=jeeves.iteminfo or {}
	if (not jeeves.itemlink) then jeeves:Hide() return end
	for i,v in pairs{GetItemInfo(itemlink)} do
			jeeves.iteminfo[i]=v
	end
	local iteminfo=jeeves.iteminfo
	--local name,_,q,ilevel=GetItemInfo(80753)
	local n=self:GetNumber("LOOK")
	LootWonAlertFrame_SetUp(jeeves,itemlink,nil,nil,nil,nil,nil,n==2,n==3 and 10 or nil)
	jeeves.Label:SetFormattedText(ITEM_LEVEL,level)
	jeeves.Label:SetTextColor(self:ChooseColor(level,iteminfo[9]))
	AlertFrame_AnimateIn(jeeves);
	--AlertFrame_StopOutAnimation(jeeves)
end
function addon:LowestLevel(itemlink1,itemlink2)
--@debug@
print("Calculating level for",itemlink1,itemlink2)
--@end-debug@
	local livello1
	local livello2
	if (itemlink1) then
		livello1=I:GetUpgradedItemLevel(itemlink1)

	--@debug@
print("1",livello1)
--@end-debug@
	end
	if (itemlink2) then
		livello2=I:GetUpgradedItemLevel(itemlink2)
	--@debug@
print("2",livello2)
--@end-debug@
	end
	if (not livello1) then return livello2 end
	if (not livello2) then return livello1 end
	if (livello1>livello2) then return livello2 else return livello1 end
end
function addon:HasArmorClass(itemlink)
	local slot=GetItemInfo(itemlink,9)
	if (slot=='INVTYPE_HEAD' or
		slot=='INVTYPE_SHOULDER' or
		slot=='INVTYPE_CHEST' or
		slot=='INVTYPE_ROBE' or
		slot=='INVTYPE_WAIST' or
		slot=='INVTYPE_LEGS' or
		slot=='INVTYPE_FEET' or
		slot=='INVTYPE_WRIST' or
		slot=='INVTYPE_HAND'
		)
		then
			return true
		end
end
-- Ugly, but i dont have another quick way to mark this item for more than 1 slot
function addon:ChooseColor(level,loc)

	local perc=self:Compare(level,loc)
	local difficulty='impossible'
	if (perc < 90) then
			difficulty='trivial'
	elseif(perc<101) then
			difficulty='standard'
	elseif (perc <105) then
			difficulty='difficult'
	elseif(perc<110) then
			difficulty='verydifficult'
	end
	local q=QuestDifficultyColors[difficulty]
	return q.r,q.g,q.b
end
function addon:Compare(level,loc)
	local slot1=slotTable[loc].s1
	local slot2=slotTable[loc].s2
	local corrente=self:LowestLevel(
						GetInventoryItemLink("player",slot1),
						slot2 and GetInventoryItemLink("player",slot2) or nil
				)
	return level/(corrente or 1)*100
end
function addon:ValidArmorClass(itemlink)

	if (self:HasArmorClass(itemlink)) then
		if (not armorClass) then
			armorClass=armorClasses[select(2,UnitClass("player"))]
		end
		if (armorClass) then
			return armorClass==GetItemInfo(itemlink,13)
		end
	else
		return true
	end

end
function addon:PreSelectReward()
	local price,id;
	for i=1,GetNumQuestChoices() do
		local itemlink = GetQuestItemLink("choice",i);
		if itemlink then
			local itemprice = GetItemInfo(itemlink,11) or 0;
			if (not price) or (itemprice > price) then
				price = itemprice;
				id = i;
			end
			local questItem=_G["QuestInfoRewardsFrameQuestInfoItem"..i]
			if (self:GetBoolean('DIM')) then
				local newlevel=I:GetUpgradedItemLevel(itemlink)
				if (not self:ValidArmorClass(itemlink)) then
					SetItemButtonDesaturated(questItem, true);
				elseif (self:Compare(newlevel,GetItemInfo(itemlink,9))<self:GetNumber("MINLEVEL")) then
					SetItemButtonDesaturated(questItem, true);
				else
					SetItemButtonDesaturated(questItem, false);
				end
			else
				SetItemButtonDesaturated(questItem, false);
			end
		end
	end
	if (id) then
		local frame=_G["QuestInfoRewardsFrameQuestInfoItem"..id]
		if (frame) then
			QuestInfoItem_OnClick(frame);
		end
	end
end
function addon:OnInitialized()
	if type(I.GetCachingGetItemInfo)=="function" then
		GetItemInfo=I:GetCachingGetItemInfo()
	else
		GetItemInfo=function(link,index)
			if index then
				return select(index,C_Item.GetItemInfo(link))
			else
				return C_Item.GetItemInfo(link)
			end
		end
	end
	OneChoice=C_AddOns.IsAddOnLoaded("OneChoice")
	GetItemInfo(6256)
	self:ShowEquipRequest()
	local qselection={}
	for i=1,4 do
		qselection[i]=_G['ITEM_QUALITY'..i..'_DESC']
	end
	local lselection={
		[95]="5% under " .. STAT_AVERAGE_ITEM_LEVEL_TOOLTIP,
		[100]= STAT_AVERAGE_ITEM_LEVEL_TOOLTIP,
		[101]= "1% over " .. STAT_AVERAGE_ITEM_LEVEL_TOOLTIP,
		[102]= "2% over " .. STAT_AVERAGE_ITEM_LEVEL_TOOLTIP,
	}
	if (not OneChoice) then
		self:AddBoolean('DIM',true,L['Dim suboptimal quest rewards'],L['Items not your preferred type are grayed out']).width='full'
	end
	self:AddSelect('MINQUAL',1,qselection,MINIMUM .. ' ' .. RARITY,L['Ignore items under this level of quality'])
	self:AddSelect('MINLEVEL',100,lselection,LFG_LIST_ITEM_LEVEL_REQ,L['Ignore items under this level of quality'])
	self:AddText('')
	local aselection={}
	aselection[1]=DEFAULT
	aselection[2]=CALENDAR_TYPE_PVP
	aselection[3]=GARRISON_LOCATION_TOOLTIP
	self:AddSelect('LOOK',1,aselection,APPEARANCE_LABEL,L["Appearance of popup button"])
	self:AddText('')
	self:AddAction('demo',L["Show an example"])
	self:AddText('')
	self:loadHelp()
--@debug@
	self:AddOpenCmd('redo','redo')
	self:AddOpenCmd('test','test')
--@end-debug@
end
function addon:OnEnabled()
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:SecureHook("GetQuestReward")
	self:SecureHook("BuyMerchantItem")
	self:RegisterEvent("QUEST_COMPLETE","PreSelectReward");
	self:RegisterEvent("QUEST_ITEM_UPDATE","PreSelectReward");
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end
function addon:OnDisabled()
	self:UnregisterAll()
	self:UnhokAll()
end
---@diagnostic disable-next-line: inject-field
_G.JVS=addon