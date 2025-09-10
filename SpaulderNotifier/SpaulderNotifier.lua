SN = { name = "SpaulderNotifier" }

local function IsWearingSpaulder()
	--hasSet, setName, numBonuses, numNormal, maxEquipped, setID, numPerfected
	local _, _, _, _, _, setID, _ = GetItemLinkSetInfo(GetItemLink(BAG_WORN, EQUIP_SLOT_SHOULDERS))
	
	if setID == 627 then
		return true
	else
		if SN.savedVariables.activeSpaulder then 
			SN.savedVariables.activeSpaulder = false
		end
		if SpaulderDisplay:IsHidden() == false then
			SpaulderDisplay:SetHidden(true)
		end
		return false
	end
end

function SN.OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
	if abilityID == 163359 and IsWearingSpaulder() then
		if result == ACTION_RESULT_EFFECT_GAINED then
			SN.savedVariables.activeSpaulder = true
			SpaulderDisplay:SetHidden(true)
		elseif result == ACTION_RESULT_EFFECT_FADED then
			SN.savedVariables.activeSpaulder = false
			SpaulderDisplay:SetHidden(false)
		end
	end
end

function SN.onUpdateEquips(code, bagID, slotIndex, isNewItem, soundCategory, updateReason, stackChange)
	if IsWearingSpaulder() then
		SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
	end
end

function SN.onTravel(code, initial)
	if (SN.firstLogin or initial) and SN.savedVariables.currentZoneID ~= GetUnitRawWorldPosition("player") then
		SN.savedVariables.activeSpaulder = false
		if IsWearingSpaulder() then SpaulderDisplay:SetHidden(false) end
		SN.savedVariables.currentZoneID = GetUnitRawWorldPosition("player")
		SN.firstLogin = false
	end
end


function SN.Initialize()
	SN.defaults = {
		activeSpaulder = true,
		currentZoneID = -1,
	}
	SN.savedVariables = ZO_SavedVars:New("SNSavedVariables", 1, nil, SN.defaults, GetWorldName())
	if IsWearingSpaulder() then
		SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
	end
	
	SN.firstLogin = true
	
	EVENT_MANAGER:RegisterForEvent(SN.name, EVENT_COMBAT_EVENT, SN.OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(SN.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SN.onUpdateEquips)
	EVENT_MANAGER:RegisterForEvent(SN.name, EVENT_ARMORY_BUILD_RESTORE_RESPONSE, SN.onUpdateEquips)
	EVENT_MANAGER:RegisterForEvent(SN.name, EVENT_PLAYER_ACTIVATED, SN.onTravel)
end

function SN.OnAddOnLoaded(event, addonName)
	if addonName == SN.name then
		SN.Initialize()
		EVENT_MANAGER:UnregisterForEvent(SN.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(SN.name, EVENT_ADD_ON_LOADED, SN.OnAddOnLoaded)