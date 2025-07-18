-- this is an example/ default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via thier ids
-- it will also load the AP slot data in the global SLOT_DATA, keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/option_mapping.lua")

if Highlight then
    HINT_STATUS_MAPPING = {
        [20] = Highlight.Avoid,
        [40] = Highlight.None,
        [10] = Highlight.NoPriority,
        [0] = Highlight.Unspecified,
        [30] = Highlight.Priority,
    }
else
    HINT_STATUS_MAPPING = {}
end

CUR_INDEX = -1
SLOT_DATA = nil
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

local AUTOTRACKER_CONNECTED = 3
local AP_TEAM_NONE = -1

ForceUpdateTab = false

function getDataStorageKey(key)
    local player = Archipelago.PlayerNumber
    local team = Archipelago.TeamNumber

    if AutoTracker:GetConnectionState("AP") ~= AUTOTRACKER_CONNECTED
        or team == nil or team == AP_TEAM_NONE
        or player == nil
    then
        print("Tried to call getDataStorageKey while not connected to AP server")
        return nil
    end

    return string.format("%s_%s_%s", key, team, player)
end

function onClear(slot_data)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
    end
    SLOT_DATA = slot_data
    CUR_INDEX = -1
    -- reset locations
    for _, v in pairs(LOCATION_MAPPING) do
        if v[1] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing location %s", v[1]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[1]:sub(1, 1) == "@" then
                    obj.AvailableChestCount = obj.ChestCount
                    if obj.Highlight then
                        obj.Highlight = Highlight.None
                    end
                else
                    obj.Active = false
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: could not find object for code %s", v[1]))
            end
        end
    end
    -- reset items
    for _, v in pairs(ITEM_MAPPING) do
        if v[1] and v[2] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing item %s of type %s", v[1], v[2]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[2] == "toggle" then
                    obj.Active = false
                elseif v[2] == "progressive" then
                    obj.CurrentStage = 0
                    obj.Active = false
                elseif v[2] == "consumable" then
                    obj.AcquiredCount = 0
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown item type %s for code %s", v[2], v[1]))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: could not find object for code %s", v[1]))
            end
        end
    end
    LOCAL_ITEMS = {}
    GLOBAL_ITEMS = {}

    --[[
    -- reset options
    for _, v in pairs(SLOT_DATA_MAPPING) do
        if v[1] and v[2] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing option %s of type %s", v[1], v[2]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[2] == "toggle" then
                    obj.Active = false
                elseif v[2] == "progressive" then
                    obj.CurrentStage = 0
                    obj.Active = false
                elseif v[2] == "consumable" then
                    obj.AcquiredCount = 0
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown item type %s for code %s", v[2], v[1]))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: unknown option %s", v[1]))
            end
        end
    end
    ]]

    if SLOT_DATA == nil then return end

    local data_storage_keys = { getDataStorageKey("_read_hints") }
    Archipelago:SetNotify(data_storage_keys)
    Archipelago:Get(data_storage_keys)

    -- set options
    for k, v in pairs(SLOT_DATA) do
        local option = SLOT_DATA_MAPPING[k]
        if option ~= nil then
            local name = option[1]
            local type = option[2]
            local obj = Tracker:FindObjectForCode(name)
            if obj then
                if type == "toggle" then
                    obj.Active = v and v ~= 0
                elseif type == "progressive" then
                    obj.CurrentStage = v
                    obj.Active = v ~= 0
                elseif type == "consumable" then
                    obj.AcquiredCount = v
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown item type %s for code %s", type, name))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: unknown option %s", name))
            end
        end
    end
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
    end
    if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
        return
    end
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local v = ITEM_MAPPING[item_id]
    if not v then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: could not find item mapping for id %s", item_id))
        end
        return
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: code: %s, type %s", v[1], v[2]))
    end
    if not v[1] then
        return
    end
    local obj = Tracker:FindObjectForCode(v[1])
    if obj then
        if v[2] == "toggle" then
            obj.Active = true
        elseif v[2] == "progressive" then
            if obj.Active then
                obj.CurrentStage = obj.CurrentStage + 1
            else
                obj.Active = true
            end
        elseif v[2] == "consumable" then
            obj.AcquiredCount = obj.AcquiredCount + obj.Increment
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: unknown item type %s for code %s", v[2], v[1]))
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: could not find object for code %s", v[1]))
    end
    -- track local items via snes interface
    if is_local then
        if LOCAL_ITEMS[v[1]] then
            LOCAL_ITEMS[v[1]] = LOCAL_ITEMS[v[1]] + 1
        else
            LOCAL_ITEMS[v[1]] = 1
        end
    else
        if GLOBAL_ITEMS[v[1]] then
            GLOBAL_ITEMS[v[1]] = GLOBAL_ITEMS[v[1]] + 1
        else
            GLOBAL_ITEMS[v[1]] = 1
        end
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
        print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
    end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onLocation: %s, %s", location_id, location_name))
    end
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
        return
    end
    local v = LOCATION_MAPPING[location_id]
    if not v and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
    end
    if not v[1] then
        return
    end
    local obj = Tracker:FindObjectForCode(v[1])
    if obj then
        if v[1]:sub(1, 1) == "@" then
            obj.AvailableChestCount = obj.AvailableChestCount - 1
        else
            obj.Active = true
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onLocation: could not find object for code %s", v[1]))
    end
end

function onDataStorageUpdate(key, value, old_value)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onDataStorageUpdate: %s, %s, %s", key, value, old_value))
    end
    if key == getDataStorageKey("_read_hints") then
        updateHints(value)
    end
end

function updateHints(hints)
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then return end
    for _, hint in ipairs(hints) do
        if hint.finding_player == Archipelago.PlayerNumber then
            updateHint(hint)
        end
    end
end

function updateHint(hint)
    -- get the highlight enum value for the hint status
    local hint_status = hint.status
    local highlight_code = nil
    if hint_status then
        highlight_code = HINT_STATUS_MAPPING[hint_status]
    end

    if not highlight_code then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status, hint.location))
        end
        -- try to "recover" by checking hint.found (older AP versions without hint.status)
        if hint.found == true then
            highlight_code = Highlight.None
        elseif hint.found == false then
            highlight_code = Highlight.Unspecified
        else
            return
        end
    end

    -- get the location mapping for the location id
    local mapping_entry = LOCATION_MAPPING[hint.location]
    if not mapping_entry then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("updateHint: could not find location mapping for id %s", hint.location))
        end
        return
    end
    for _, location_code in pairs(mapping_entry) do
        -- skip hosted items, they don't support Highlight
        if location_code and location_code:sub(1, 1) == "@" then
            -- find the location object
            local obj = Tracker:FindObjectForCode(location_code)
            -- check if we got the location and if it supports Highlight
            if obj and obj.Highlight then
                obj.Highlight = highlight_code
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
                print(string.format("updateHint: could update section %s (obj doesn't support Highlight)", location_code))
            end
        end
    end
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    Archipelago:AddLocationHandler("location handler", onLocation)
end
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)

REVERSE_LOCATION_MAPPING = {}
for id, name in pairs(LOCATION_MAPPING) do
    REVERSE_LOCATION_MAPPING[string.sub(name[1], 2)] = id
end

local function sendVictory(section)
    local res = Archipelago:StatusUpdate(Archipelago.ClientStatus.GOAL)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        if res then
            print("sendVictory: Sent Victory for section " .. section.FullID)
        else
            print("sendVictory: Error sending Victory for section" .. section.FullID)
        end
    end
end

local function sendLocation(section)
    local section_id = section.FullID
    local ap_id = REVERSE_LOCATION_MAPPING[section_id]
    if ap_id ~= nil then
        local res = Archipelago:LocationChecks({ap_id})
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            if res then
                print(string.format("sendLocation: Sent ID %d for section %s"), ap_id, section_id)
            else
                print(string.format("sendLocation: Error sending ID %d for section %s"), ap_id, section_id)
            end
        end
    else
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("sendLocation: No AP location found for section %s"), ap_id, section_id)
        end
    end
end

ScriptHost:AddOnLocationSectionChangedHandler("Manual", function(section)
    if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then return end
    if AutoTracker:GetConnectionState("AP") ~= AUTOTRACKER_CONNECTED then return end
    if (section.AvailableChestCount > 0) then return end

    if section.FullID == "Deepsea Metro/A00 - Central Station/Game Complete" then
        sendVictory(section)
    else
        sendLocation(section)
    end
end)
