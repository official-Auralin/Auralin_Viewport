local addonName, AuralinVP = ...

local eventFrame = CreateFrame("Frame")

function UpdateWorldFrame()
    local bottom    = Auralin_Viewport_Settings.bottom or 112
    local top       = Auralin_Viewport_Settings.top or 0
    local left      = Auralin_Viewport_Settings.left or 0
    local right     = Auralin_Viewport_Settings.right or 0

    -- Adjust the WorldFrame's size and position
    WorldFrame:ClearAllPoints()
    WorldFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", left, -top)
    WorldFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", -right, bottom)

    -- Ensure the dummy frames reflect these offsets
    if AuralinVP.dummyFrames then
        AuralinVP.dummyFrames.top:SetHeight(top)
        AuralinVP.dummyFrames.bottom:SetHeight(bottom)
        AuralinVP.dummyFrames.left:SetWidth(left)
        AuralinVP.dummyFrames.right:SetWidth(right)
    end

    print("WorldFrame updated with settings: top =", top, ", left =", left, ", right =", right, ", bottom =", bottom, ".")
end

-- Register Events for the event frame
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CINEMATIC_STOP")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Call a function to update the sliders.
        UpdateSlidersWithCurrentSettings()
        UpdateWorldFrame()
    elseif event == "CINEMATIC_STOP" then 
        UpdateWorldFrame()
    elseif event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize Auralin_Viewport_Settings if it's nil
        if Auralin_Viewport_Settings == nil then
            Auralin_Viewport_Settings = { bottom = 112, top = 0, left = 0, right = 0 }
        end
        UpdateWorldFrame()
    end
end)
