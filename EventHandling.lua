local addonName, AuralinVP = ...

local eventFrame = CreateFrame("Frame")

function AuralinVP:ApplyViewportSettings()
    if self.InitializePersistentData then
        self:InitializePersistentData()
    end

    if not self.GetStoredSettings then
        return
    end

    local settings = self:GetStoredSettings()
    self:RestoreWorldFrame(settings.left, settings.top, settings.right, settings.bottom)

    if self.dummyFrames then
        self.dummyFrames.top:SetHeight(self:ConvertWorldUnitsToPreviewUnits(settings.top))
        self.dummyFrames.bottom:SetHeight(self:ConvertWorldUnitsToPreviewUnits(settings.bottom))
        self.dummyFrames.left:SetWidth(self:ConvertWorldUnitsToPreviewUnits(settings.left))
        self.dummyFrames.right:SetWidth(self:ConvertWorldUnitsToPreviewUnits(settings.right))

        if self.RefreshDummyFrameSideAnchors then
            self:RefreshDummyFrameSideAnchors()
        end
    end
end

local function OnEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName ~= addonName then
            return
        end

        AuralinVP:InitializePersistentData()
        AuralinVP:ApplyViewportSettings()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        AuralinVP:ApplyViewportSettings()
    elseif event == "CINEMATIC_STOP" or event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        AuralinVP:ApplyViewportSettings()
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CINEMATIC_STOP")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:SetScript("OnEvent", OnEvent)
