local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local toc=select(4,GetBuildInfo())
local me, ns = ...
local pp=print
if (LibDebug) then LibDebug() end
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local C=LibStub("AlarCrayon-3.0"):GetColorTable()
local addon=LibStub("AlarLoader-3.0")(__FILE__,me,ns):CreateAddon(me,true) --#Addon
local print=ns.print or print
local debug=ns.debug or print
-----------------------------------------------------------------
local D=LibStub("LibDeformat-3.0")
local I=LibStub("LibItemUpgradeInfo-1.0",true)
local lastitem
local jeeves
local SetItemButtonTexture= SetItemButtonTexture
local SetItemButtonCount=SetItemButtonCount
local GetItemInfo=addon:GetCachingGetItemInfo()
local GetQuestItemLink=GetQuestItemLink
local GetMerchantItemLink=GetMerchantItemLink
local GetContainerNumSlots=GetContainerNumSlots
local GetContainerItemID=GetContainerItemID
local PickupContainerItem=PickupContainerItem
local ToggleCharacter=ToggleCharacter
local GameTooltip_ShowCompareItem=GameTooltip_ShowCompareItem
local GameTooltip=GameTooltip
local CharacterFrame=CharacterFrame
local CursorUpdate=CursorUpdate
local ResetCursor=ResetCursor
local CreateFrame=CreateFrame
local LOOT_ITEM_SELF=LOOT_ITEM_SELF
local GetItemQualityColor=GetItemQualityColor
local QuestDifficultyColors=QuestDifficultyColors
local _G=_G
function addon:OnInitialized()
	GetItemInfo(6256)
	if (D) then
		self:RegisterEvent("CHAT_MSG_LOOT")
		self:SecureHook("GetQuestReward")
		self:SecureHook("BuyMerchantItem")
		self:ShowEquipRequest()
		local qselection={}
		for i=1,4 do
			qselection[i]=_G['ITEM_QUALITY'..i..'_DESC']
		end
		self:AddSelect('MINQUAL',1,qselection,MINIMUM .. ' ' .. RARITY,L['Ignore items under this level of quality'])
		self:AddText('')
		local aselection={}
		aselection[1]=DEFAULT
		aselection[2]=CALENDAR_TYPE_PVP
		aselection[3]=GARRISON_LOCATION_TOOLTIP
		self:AddSelect('LOOK',1,aselection,APPEARANCE_LABEL,L["Appearance of popup button"])
		self:AddText('')
		self:AddAction('demo',L["Show an example"])
		self:AddText('')
		--self:loadHelp()
--@debug@
		self:AddOpenCmd('redo','redo')
		self:AddOpenCmd('test','test')
--@debug-end@
	else
	error("Cant found LibDeformat-3.0")
	end
end
local autoitem=1
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
--@debug-end@
function addon:demo()
	lastitem=select(2,GetItemInfo(6256))
	self:redo()
	lastitem=nil
end
function addon:redo()
	if (lastitem) then
		self:AskEquip(lastitem)
	end
end

function addon:GetItemID(itemlink)
	if (type(itemlink)=="string") then
			return tonumber(itemlink:match("Hitem:(%d+):")) or 0
	else
			return 0
	end
end
function addon:CHAT_MSG_LOOT(evt,p1)
	local newLink=D.Deformat(p1,LOOT_ITEM_SELF)
	local rc,name,itemlink,rarity,level,minlevel,type,subtype,count,loc,texture,price=pcall(GetItemInfo,newLink)
	if (not rc) then
			debug(p1, "has not a valid itemlink:",newLink)
	end
	if (loc and loc~='') then
			debug("Dropped equippable object",name,loc,_G[loc])
			self:AskEquip(itemlink)
	end
end
function addon:GetQuestReward(choice)
	local itemlink=GetQuestItemLink("choice",choice)
	debug("Assegnato reward",itemlink)
	self:AskEquip(itemlink)
end
function addon:BuyMerchantItem(choice)
	local itemlink=GetMerchantItemLink(choice)
	debug("Acquistato oggetto",itemlink)
	self:AskEquip(itemlink)
end
function addon:OnClick(this,button,opt)
		debug("Clicked",button,opt)
		if (button=="LeftButton") then
			local foundid,bag,slot=self:ScanBags(0,addon:GetItemID(this.itemlink))
			debug(foundid,bag,slot)
			if (bag and slot) then
					PickupContainerItem(bag,slot)
					debug("Will equip ",this.iteminfo[1])
					if (not CharacterFrame:IsShown()) then
						ToggleCharacter("PaperDollFrame")
					end
			else
					self:Onscreen_Red(this.iteminfo[1] .. ': ' .. ERR_ITEM_NOT_FOUND)
			end
		end
		jeeves:Hide()
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
	print(GetItemInfo(itemlink))
	if (IsEquippableItem(itemlink) and select(3,GetItemInfo(itemlink)) >= self:GetNumber('MINQUAL')) then
		lastitem=itemlink
		if (InCombatLockdown()) then
			self:ScheduleLeaveCombatAction('ShowEquipRequest',itemlink)
		else
			self:ScheduleTimer('ShowEquipRequest',1,itemlink)
		end
	end
end
function addon:APPLY(...)
	debug("Apply",...)
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
	jeeves.Label:SetFormattedText(ITEM_LEVEL,iteminfo[4])
	jeeves.Label:SetTextColor(self:ChooseColor(iteminfo))
	AlertFrame_AnimateIn(jeeves);
	AlertFrame_StopOutAnimation(jeeves)
end
function addon:LowestLevel(itemlink1,itemlink2)
	debug("Calculating level for",itemlink1,itemlink2)
	local livello1
	local livello2
	if (itemlink1) then
			livello1=select(4,GetItemInfo(itemlink1))
			if (I) then
				livello1=livello1+I:GetItemLevelUpgrade(I:GetUpgradeID(itemlink1))
			end
	end
	if (itemlink2) then
			livello2=select(4,GetItemInfo(itemlink2))
			if (I) then
				livello2=livello2+I:GetItemLevelUpgrade(I:GetUpgradeID(itemlink2))
			end
	end
	if (not livello1) then return livello2 end
	if (not livello2) then return livello1 end
	if (livello1>livello2) then return livello2 else return livello1 end
end
function addon:loc2slots(loc)
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
			end
	else
			return _G[slot]
	end
end
function addon:ChooseColor(iteminfo)
	debug(unpack(iteminfo))
	local slot1,slot2=self:loc2slots(iteminfo[9])
	local nuovo=iteminfo[4] -- We assume that no item can drop already upgraded
	local corrente=self:LowestLevel(
						GetInventoryItemLink("player",slot1),
						slot2 and GetInventoryItemLink("player",slot2) or nil
				)
	local perc=nuovo/(corrente or 1)*100
	debug(nuovo,corrente,perc)
	local difficulty='impossible'
	if (perc < 60) then
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


_G.JVS=addon