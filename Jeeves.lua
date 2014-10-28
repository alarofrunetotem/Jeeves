local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local toc=select(4,GetBuildInfo())
local me, ns = ...
local pp=print
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
local GetItemInfo=GetItemInfo
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
local _G=_G
function addon:OnInitialized()
	if (D) then
		self:RegisterEvent("CHAT_MSG_LOOT")
		self:SecureHook("GetQuestReward")
		self:SecureHook("BuyMerchantItem")
		self:ShowEquipRequest()
		print("Jeeves ready in your orders")
		self:AddChatCmd('redo','redo')
		local selection={}
		for i=1,4 do
			selection[i]=_G['ITEM_QUALITY'..i..'_DESC']
		end
		self:AddSelect('MINQUAL',1,selection,"Min qual")--L['Ignore items under this quality'])
	else
	error("Cant found LibDeformat-3.0")
	end
end
function addon:redo()
	if (lastitem) then
		print("Redoing",select(2,GetItemInfo(lastitem),''))
		self:AskEquip(lastitem)
	else
		print("No last item")
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
			print(p1, "has not a valid itemlink:",newLink)
	end
	if (loc and loc~='') then
			print("Dropped equippable object",name,loc,_G[loc])
			self:AskEquip(itemlink)
	end
end
function addon:GetQuestReward(choice)
	local itemlink=GetQuestItemLink("choice",choice)
	print("Assegnato reward",itemlink)
	self:AskEquip(itemlink)
end
function addon:BuyMerchantItem(choice)
	local itemlink=GetMerchantItemLink(choice)
	print("Acquistato oggetto",itemlink)
	self:AskEquip(itemlink)
end
--[[
function addon:ScanBags(index,value,startbag,startslot)
	index=index or 0
	value=value or 0
	startbag=startbag or 0
	startslot=startslot or 1
	for bag=startbag,NUM_BAG_SLOTS,1 do
		for slot=startslot,GetContainerNumSlots(bag),1 do
			local itemid=GetContainerItemID(bag,slot) or 0
			if (index==0) then
				if (itemid==value) then
					print("FOUND",itemid,select(1,GetItemInfo(itemid)))
					return itemid,bag,slot,GetItemInfo(itemid)
				end
			else
				if (select(index,GetItemInfo(itemid))) then
					return itemid,bag,slot,unpack(result)
				end
			end
		end
	end
	return false
end
--]]
function addon:OnClick(this,button,opt)
		print("Clicked",button,opt)
		if (button=="LeftButton") then
			local foundid,bag,slot=self:ScanBags(0,addon:GetItemID(this.itemlink))
			print(foundid,bag,slot)
			if (bag and slot) then
					PickupContainerItem(bag,slot)
					debug("Will equip ",this.iteminfo[1])
					if (not CharacterFrame:IsShown()) then
						ToggleCharacter("PaperDollFrame")
					end
			else
					error("Unable to find item in bags:" .. this.iteminfo[1])
			end
		end
		jeeves:Hide()
end
function addon:ToolTip(this)
					GameTooltip:SetOwner(this, "ANCHOR_NONE");
					GameTooltip:SetPoint("TOPLEFT",this,"BOTTOMLEFT")
					GameTooltip:SetHyperlink(this.itemlink)
					GameTooltip:AddLine("Left-Click to equip")
					GameTooltip:AddLine("Right-Click to dismiss")
					GameTooltip:Show()
					GameTooltip_ShowCompareItem(GameTooltip);
					CursorUpdate(this);
end
function addon:AskEquip(itemlink)
	if (IsEquippableItem(itemlink) and select(3,GetItemInfo(itemlink)) >= self:GetNumber('MINQUAL')) then
		lastitem=itemlink
		if (InCombatLockdown()) then
			self:ScheduleLeaveCombatAction('ShowEquipRequest',itemlink)
		else
			self:ScheduleTimer('ShowEquipRequest',1,itemlink)
		end
	end
end
function addon:ShowEquipRequest(itemlink)
	if (not jeeves) then
			jeeves=CreateFrame("CheckButton",'jeevesFrame',UIParent,"LargeItemButtonTemplate")
			jeeves:SetPoint("CENTER",UIParent,"CENTER",0,300)
			jeeves:RegisterForClicks("AnyUp")
			jeeves:SetScript("OnClick",function(...) addon:OnClick(...) end)
			jeeves:SetScript("OnEnter",function(...) addon:ToolTip(...) end)
			jeeves:SetScript("OnLeave",function() GameTooltip:Hide() ResetCursor() end)
			jeeves:SetPoint("CENTER",UIParent,"CENTER",0,300)
			jeeves:RegisterForClicks("AnyUp")
			jeeves.fname=jeevesFrameName
			jeeves.fcount=jeevesFrameCount
	end
	jeeves.itemlink=itemlink
	jeeves.iteminfo=jeeves.iteminfo or {}
	if (not jeeves.itemlink) then jeeves:Hide() return end
	for i,v in pairs{GetItemInfo(itemlink)} do
			jeeves.iteminfo[i]=v
	end
	local iteminfo=jeeves.iteminfo
	--local name,_,q,ilevel=GetItemInfo(80753)
	SetItemButtonTexture(jeeves,iteminfo[10])
	SetItemButtonCount(jeeves,iteminfo[4])
	jeeves.fname:SetText(iteminfo[1])
	jeeves.fname:SetTextColor(GetItemQualityColor(iteminfo[3]))
	jeeves.fcount:SetTextColor(self:ChooseColor(iteminfo))
	jeeves:Show()
end
function addon:LowestLevel(itemlink1,itemlink2)
	print("Calculating level for",itemlink1,itemlink2)
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

function addon:ChooseColor(iteminfo)
	print(unpack(iteminfo))
	local slot=iteminfo[9]:gsub('INVTYPE','INVSLOT')
	local nuovo=iteminfo[4]
	print(slot)
	local corrente
	if (not _G[slot]) then
			if (slot=='INVSLOT_FINGER' or slot=='INVSLOT_TRINKET') then
				corrente=self:LowestLevel(
						GetInventoryItemLink("player",_G[slot..'1']),
						GetInventoryItemLink("player",_G[slot..'2'])
				)
			elseif (slot=='INVSLOT_WEAPON') then
				corrente=self:LowestLevel(
						GetInventoryItemLink("player",INVSLOT_MAINHAND),
						GetInventoryItemLink("player",INVSLOT_OFFHAND)
				)
			elseif  (slot=='INVSLOT_2HWEAPON' or slot=='INVSLOT_WEAPONMAINHAND') then
				corrente=self:LowestLevel( GetInventoryItemLink("player",INVSLOT_MAINHAND))
			elseif  (slot=='INVSLOT_HOLDABLE' or slot=='INVSLOT_WEAPONOFFHAND') then
				corrente=self:LowestLevel( GetInventoryItemLink("player",INVSLOT_OFFHAND))
			elseif  (slot=='INVSLOT_RANGED' or slot=='INVSLOT_THROWN') then
				corrente=self:LowestLevel( GetInventoryItemLink("player",INVSLOT_RANGED))
			end
	else
			print("Attempting",slot)

			corrente=self:LowestLevel( GetInventoryItemLink("player",_G[slot]))
	end
	local perc=nuovo/corrente*100
	print(nuovo,corrente,perc)
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