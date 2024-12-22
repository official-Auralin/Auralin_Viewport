local addonName, AuralinVP = ...
local Constants = AuralinVP.Constants

local eventFrame = CreateFrame("Frame")

function UpdateWorldFrame()
    local bottom    = Auralin_Viewport_Settings.bottom  or Constants.DEFAULT_BOTTOM
    local top       = Auralin_Viewport_Settings.top     or Constants.DEFAULT_TOP
    local left      = Auralin_Viewport_Settings.left    or Constants.DEFAULT_LEFT
    local right     = Auralin_Viewport_Settings.right   or Constants.DEFAULT_RIGHT

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
