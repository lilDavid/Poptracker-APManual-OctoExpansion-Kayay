DEBUG = true
ENABLE_DEBUG_LOG = true

IS_ITEMS_ONLY = Tracker.ActiveVariantUID == "var_1_itemsonly"

ScriptHost:LoadScript("scripts/utils.lua")

Tracker:AddItems("items/items.json")
if not IS_ITEMS_ONLY then
    Tracker:AddItems("items/options.json")

    Tracker:AddMaps("maps/maps.json")

    Tracker:AddLocations("locations/locations.json")
end

Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/broadcast.json")
if not IS_ITEMS_ONLY then
    Tracker:AddLayouts("layouts/maps.json")
    Tracker:AddLayouts("layouts/tracker.json")
    Tracker:AddLayouts("layouts/options.json")

    ScriptHost:LoadScript("scripts/logic/logic.lua")
    ScriptHost:LoadScript("scripts/goal.lua")
end

if PopVersion and PopVersion >= "0.18.0" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
end