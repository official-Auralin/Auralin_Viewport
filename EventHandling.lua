local addonName, AuralinVP = ...

local eventFrame = CreateFrame("Frame")

-- Register the PLAYER_ENTERING_WORLD event
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Register the ADDON_LOADED event
eventFrame:RegisterEvent("ADDON_LOADED")

-- Register the CINEMATIC_STOP event
eventFrame:RegisterEvent("CINEMATIC_STOP")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Call a function to update the sliders.
        UpdateSlidersWithCurrentSettings()
    elseif event == "CINEMATIC_STOP" then 
        UpdateWorldFrame()
    elseif event == "ADDON_LOADED" and addonName == "Auralin_Viewport" then
        -- Initialize Auralin_Viewport_Settings if it's nil
        if Auralin_Viewport_Settings == nil then
            Auralin_Viewport_Settings = { bottom = 112, top = 0, left = 0, right = 0 }
        end
        UpdateWorldFrame()
    end
end)

function UpdateWorldFrame()
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    local bottom = Auralin_Viewport_Settings.bottom or 112
    local top = Auralin_Viewport_Settings.top or 0
    local left = Auralin_Viewport_Settings.left or 0
    local right = Auralin_Viewport_Settings.right or 0

    -- Set the WorldFrame to the new viewport settings
    WorldFrame:ClearAllPoints()
    WorldFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, -top)
    WorldFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -right, bottom)
    print("WorldFrame updated with settings: ", top, left, right, bottom)
end

-- Set the event handler
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    -- When the ADDON_LOADED event fires for this addon
    if event == "ADDON_LOADED" and addonName == "Auralin_Viewport" then
        -- Initialize Auralin_Viewport_Settings if it's nil
        if Auralin_Viewport_Settings == nil then
            Auralin_Viewport_Settings = { bottom = 112, top = 0, left = 0, right = 0 }
        end
        UpdateWorldFrame()
    end    
end)
