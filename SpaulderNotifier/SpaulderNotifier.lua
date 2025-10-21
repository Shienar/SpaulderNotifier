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
	if abilityID == 163359 and targetType == COMBAT_UNIT_TYPE_PLAYER and IsWearingSpaulder() then
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

		
		selectedFontNumber = "42",
		selectedFontName = "ZoFontGamepad42",
		color = {
			red = 1,
			green= 0,
			blue = 0,
			alpha = 1,
		},
		offset_x = 0,
		offset_y = -300;
	}

	SN.savedVariables = ZO_SavedVars:New("SNSavedVariables", 1, nil, SN.defaults, GetWorldName())
	SpaulderDisplay:ClearAnchors()
	SpaulderDisplay:SetAnchor(CENTER, GuiRoot, CENTER, SN.savedVariables.offset_x, SN.savedVariables.offset_y)
	SpaulderDisplayLabel:SetColor(SN.savedVariables.color.red, SN.savedVariables.color.green, SN.savedVariables.color.blue)
	SpaulderDisplayLabel:SetAlpha(SN.savedVariables.color.alpha)
	SpaulderDisplayLabel:SetFont(SN.savedVariables.selectedFontName)

	if IsWearingSpaulder() then
		SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
	end
	
	--settings
	local settings = LibHarvensAddonSettings:AddAddon("Spaulder Notifier")

	local fontSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Font",}
	local positionSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Position",}

	local changeCounter = 0

	local spaulder_font = {
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = "Notifier Font Size",
        tooltip = "Change the size of the Notifier.",
        setFunction = function(combobox, name, item)
			SpaulderDisplayLabel:SetFont(item.data);
			SN.savedVariables.selectedFontNumber = name
			SN.savedVariables.selectedFontName = item.data
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			SpaulderDisplay:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if IsWearingSpaulder() then
						SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
					end
				end
			end, 5000)
        end,
        getFunction = function()
            return SN.savedVariables.selectedFontNumber
        end,
        default = SN.defaults.selectedFontNumber,
        items = {
            {
                name = "18",
                data = "ZoFontGamepad18"
            },
            {
                name = "20",
                data = "ZoFontGamepad20"
            },
            {
                name = "22",
                data = "ZoFontGamepad22"
            },
            {
                name = "25",
                data = "ZoFontGamepad25"
            },
            {
                name = "34",
                data = "ZoFontGamepad34"
            },
			{
                name = "36",
                data = "ZoFontGamepad36"
            },
            {
                name = "42",
                data = "ZoFontGamepad42"
            },
            {
                name = "54",
                data = "ZoFontGamepad54"
            },
            {
                name = "61",
                data = "ZoFontGamepad61"
            },
        },
        disable = function() return false end,
    }

	local color = {
        type = LibHarvensAddonSettings.ST_COLOR,
        label = "Color",
        tooltip = "Change the color of the label.",
        setFunction = function(...) --newR, newG, newB, newA
            SN.savedVariables.color.red, SN.savedVariables.color.green, SN.savedVariables.color.blue, SN.savedVariables.color.alpha = ...
			SpaulderDisplayLabel:SetColor(SN.savedVariables.color.red, SN.savedVariables.color.green, SN.savedVariables.color.blue)
			SpaulderDisplayLabel:SetAlpha(SN.savedVariables.color.alpha)

			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			SpaulderDisplay:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if IsWearingSpaulder() then
						SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
					end
				end
			end, 5000)
		end,
        default = {SN.defaults.color.red, SN.defaults.color.green, SN.defaults.color.blue, SN.defaults.color.alpha},
        getFunction = function()
            return SN.savedVariables.color.red, SN.savedVariables.color.green, SN.savedVariables.color.blue, SN.savedVariables.color.alpha
        end,
        disable = function() return false end,
    }

	SN.currentlyChangingPosition = false
	local repositionUI = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Joystick Reposition",
		tooltip = "When enabled, you will be able to freely move around the UI with your right joystick.\n\nSet this to OFF after configuring position.",
		getFunction = function() return SN.currentlyChangingPosition end,
		setFunction = function(value) 
			SN.currentlyChangingPosition = value
			if value == true then
				SpaulderDisplay:SetHidden(false)
				EVENT_MANAGER:RegisterForUpdate(SN.name.."AdjustUI", 10,  function() 
					local posX, posY = GetGamepadRightStickX(true), GetGamepadRightStickY(true)
					if posX ~= 0 or posY ~= 0 then 
						SN.savedVariables.offset_x = SN.savedVariables.offset_x + 10*posX
						SN.savedVariables.offset_y = SN.savedVariables.offset_y - 10*posY

						if SN.savedVariables.offset_x < (-GuiRoot:GetWidth()/2) then SN.savedVariables.offset_x = (-GuiRoot:GetWidth()/2) end
						if SN.savedVariables.offset_y < (-GuiRoot:GetHeight()/2) then SN.savedVariables.offset_y = (-GuiRoot:GetHeight()/2) end
						if SN.savedVariables.offset_x > (GuiRoot:GetWidth()/2) then SN.savedVariables.offset_x = (GuiRoot:GetWidth()/2) end
						if SN.savedVariables.offset_y >(GuiRoot:GetHeight()/2) then SN.savedVariables.offset_y = (GuiRoot:GetHeight()/2) end

						SpaulderDisplay:ClearAnchors()
						SpaulderDisplay:SetAnchor(CENTER, GuiRoot, CENTER, SN.savedVariables.offset_x, SN.savedVariables.offset_y)
					end 
				end)
			else
				EVENT_MANAGER:UnregisterForUpdate(SN.name.."AdjustUI")
				--Hide UI 5 seconds after most recent change. multiple changes can be queued.
				SpaulderDisplay:SetHidden(false)
				changeCounter = changeCounter + 1
				local changeNum = changeCounter
				zo_callLater(function()
					if changeNum == changeCounter then
						changeCounter = 0
						if IsWearingSpaulder() then
							SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
						end
					end
				end, 5000)
			end
		end,
		default = SN.currentlyChangingPosition
	}

	--x position offset
	local slider_x = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "X Offset",
        tooltip = "",
        setFunction = function(value)
			SN.savedVariables.offset_x = value
			
			SpaulderDisplay:ClearAnchors()
			SpaulderDisplay:SetAnchor(CENTER, GuiRoot, CENTER, SN.savedVariables.offset_x, SN.savedVariables.offset_y)
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			SpaulderDisplay:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if IsWearingSpaulder() then
						SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return SN.savedVariables.offset_x
        end,
        default = SN.defaults.offset_x,
        min = (-GuiRoot:GetWidth()/2),
        max = (GuiRoot:GetWidth()/2),
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return false end,
    }
	
	--y position offset
	local slider_y = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Y Offset",
        tooltip = "",
        setFunction = function(value)
			SN.savedVariables.offset_y = value

			SpaulderDisplay:ClearAnchors()
			SpaulderDisplay:SetAnchor(CENTER, GuiRoot, CENTER, SN.savedVariables.offset_x, SN.savedVariables.offset_y)
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			SpaulderDisplay:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if IsWearingSpaulder() then
						SpaulderDisplay:SetHidden(SN.savedVariables.activeSpaulder)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return SN.savedVariables.offset_y
        end,
        default = SN.defaults.offset_y,
        min = (-GuiRoot:GetHeight()/2),
        max = (GuiRoot:GetHeight()/2),
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return false end,
    }

	settings:AddSettings({fontSection, spaulder_font, color})
	settings:AddSettings({positionSection, repositionUI, slider_x, slider_y})

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