-- Utils

function has(item, n)
    local obj = Tracker:FindObjectForCode(item)
    if obj == nil then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING then
            print(string.format("has: unrecognized item %s", item))
        end
        return false
    end
    if n == nil then
        n = 1
    end
    local count
    if obj.Type == "progressive" then
        count = obj.CurrentStage
    elseif obj.Type == "consumable" then
        count = obj.AcquiredCount
    elseif obj.Active then
        count = 1
    else
        count = 0
    end
    return (count >= tonumber(n))
end

function has_all(items)
    for _, item in ipairs(items) do
        if not has(item) then
            return false
        end
    end
    return true
end

function has_any(items)
    for _, item in ipairs(items) do
        if has(item) then
            return true
        end
    end
    return false
end


-- Logic

function can_goal()
    if not has("CakeHunt") then
        return has_all({"FoundationalThang", "PrecisionThang", "SurroundingThang", "SealingThang"})
    end
    return Tracker:ProviderCountForCode("MemCake") >= Tracker:ProviderCountForCode("MemCakesNeeded")
end
