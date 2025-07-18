local function autoTrackGoal(_)
    local thang_cutscene = Tracker:FindObjectForCode("@Deepsea Metro/A00 - Central Station/Goal Obtained")
    local commander_tartar = Tracker:FindObjectForCode("@Deepsea Metro/A00 - Escape/Commander Tartar")
    local goal = Tracker:FindObjectForCode("@Deepsea Metro/A00 - Central Station/Game Complete")
    local line_escape = Tracker:FindObjectForCode("LineEscape")
    local include_escape = Tracker:FindObjectForCode("IncludeEscape")
    local final_boss_goal = Tracker:FindObjectForCode("TartarGoal")
    local escaped = Tracker:FindObjectForCode("Escaped")

    local goal_obtained = thang_cutscene ~= nil and thang_cutscene.AvailableChestCount <= 0
    if line_escape then
        line_escape.Active = goal_obtained
    end
    if escaped then
        if include_escape and include_escape.Active or final_boss_goal and final_boss_goal.Active then
            escaped.Active = commander_tartar ~= nil and commander_tartar.AvailableChestCount <= 0
        else
            escaped.Active = goal_obtained
        end
        if goal and escaped.Active then
            goal.AvailableChestCount = 0
        end
    end
end

ScriptHost:AddOnLocationSectionChangedHandler("Goal", autoTrackGoal)
