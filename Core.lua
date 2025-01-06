local addonName, AuralinVP = ...

AuralinVP.Constants = {
    DEFAULT_TOP = 0,
    DEFAULT_BOTTOM = 112,
    DEFAULT_LEFT = 0,
    DEFAULT_RIGHT = 0,
    ROUNDING_THRESHOLD = 0.5,
    MAX_SLIDER_VALUE = 500,
    DEFAULT_SLIDER_LENGTH = 200,
}
local Constants = AuralinVP.Constants
AuralinVP = AuralinVP or {}

function AuralinVP:ResetDummyFrame(frame, points, size)
    frame:ClearAllPoints()
    for _, point in ipairs(points) do
        frame:SetPoint(unpack(point))
    end
    if size.width then
        frame:SetWidth(size.width)
    elseif size.height then
        frame:SetHeight(size.height)
    end
end

function AuralinVP:RestoreWorldFrame(left, top, right, bottom)
    WorldFrame:ClearAllPoints()
    WorldFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", left, -top)
    WorldFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", -right, bottom)
end
--@alpha@
local function GetCharacterFullName()
   local name, realm = UnitName("player")
   if not name then
    return nil
   end
   if not realm or realm == " " then
    realm = GetNormalizedRealmName() or "UnknownRealm"
   end
   return realm .. "-" .. name
end

function AuralinVP:GetActiveProfileName()
    if not Auralin_Viewport_Profiles then
        Auralin_Viewport_Profiles = {}
    end
    if not Auralin_Viewport_Profiles.charSettings then
        Auralin_Viewport_Profiles.charSettings = {}
    end
    if not Auralin_Viewport_Profiles.profiles then
        Auralin_Viewport_Profiles.profiles = {}
    end
    -- fallback to "Default" if something isn't set
    local charKey = GetCharacterFullName()
    if not charKey then
        return nil
    end
    --[===[@debug@]
    local activeProfile = Auralin_Viewport_Profiles.charSettings[charKey] or "Default"
    return activeProfile
    --@end-debug@]===]
    local assignedProfile = Auralin_Viewport_Profiles.charSettings[charKey]

    --1) If assignedProfile is a non-nil but doesn't exist in profiles, delete it
    if assignedProfile and not Auralin_Viewport_Profiles.profiles[assignedProfile] then
        Auralin_Viewport_Profiles.charSettings[charKey] = nil
        assignedProfile = nil
    end
    --2) If we do not have a valid assignedProfile, try to fallback to "Default" if it exists
    if not assignedProfile then
        if Auralin_Viewport_Profiles.profiles["Default"] then
            Auralin_Viewport_Profiles.charSettings[charKey] = "Default"
            assignedProfile = "Default"
        end
    end
    --3) Return the final assigned Profile (could be "Default" or nil)
    return assignedProfile
end

function AuralinVP:GetActiveProfile()
    local profileName = self:GetActiveProfileName()
    --[===[@debug@]
    if not Auralin_Viewport_Profiles.profiles[profileName] then
        -- If the profile doesn't exist yet, ensure we create it or fallback
        profileName = "Default"
        Auralin_Viewport_Profiles.profiles[profileName] = {
            top     = Constants.DEFAULT_TOP,
            left    = Constants.DEFAULT_LEFT,
            right   = Constants.DEFAULT_RIGHT,
            bottom  = Constants.DEFAULT_BOTTOM,
        }
    end
    return Auralin_Viewport_Profiles.profiles[profileName]
    --@end-debug@]===]
    local foundProfile = profileName and Auralin_Viewport_Profiles.profiles[profileName]
    if foundProfile then
        return foundProfile
    else
        return {
            top     = Constants.DEFAULT_TOP,
            left    = Constants.DEFAULT_LEFT,
            right   = Constants.DEFAULT_RIGHT,
            bottom  = Constants.DEFAULT_BOTTOM,
        }
    end
end

function AuralinVP:GetAvailableProfiles()
    if not Auralin_Viewport_Profiles or not Auralin_Viewport_Profiles.profiles then
        return {}
    end
    local list = {}
    for profileName, _ in pairs(Auralin_Viewport_Profiles.profiles) do
        table.insert(list, profileName)
    end
    table.sort(list)
    return list
end

function AuralinVP:SetActiveProfile(profileName)
    if not Auralin_Viewport_Profiles or not Auralin_Viewport_Profiles.profiles[profileName] then
        print("AuralinVP: Cannot set active profile, does not exist: "..tostring(profileName))
        return
    end
    local charKey = GetCharacterFullName()
    Auralin_Viewport_Profiles.charSettings = Auralin_Viewport_Profiles.charSettings or {}
    Auralin_Viewport_Profiles.charSettings[charKey] = profileName

    if UpdateSlidersWithCurrentSettings then
        UpdateSlidersWithCurrentSettings()
    end
end
--@end-alpha@
--[===[@non-alpha@
function AuralinVP:GetSettingOrDefault(key)
    return Auralin_Viewport_Settings and Auralin_Viewport_Settings[key] or Constants["DEFAULT_" .. key:upper()]
end
--@end-non-alpha@]===]

function AuralinVP:DestroyDummyFrames()
    if not self.dummyFrames then return end

    for _, frame in pairs(self.dummyFrames) do
        frame:Hide()
        frame:SetParent(nil)
    end
    self.dummyFrames = nil
end

function AuralinVP:ChangesDetected()
--[===[@non-alpha@
    if not self.dummyFrames or not Auralin_Viewport_Settings then return false end
    local current = {
        top     = self.dummyFrames.top:GetHeight(),
        left    = self.dummyFrames.left:GetWidth(),
        right   = self.dummyFrames.right:GetWidth(),
        bottom  = self.dummyFrames.bottom:GetHeight(),
    }

    local saved = Auralin_Viewport_Settings or { 
        top     = Constants.DEFAULT_TOP, 
        left    = Constants.DEFAULT_LEFT, 
        right   = Constants.DEFAULT_RIGHT, 
        bottom  = Constants.DEFAULT_BOTTOM
    }

    return current.top ~= saved.top or current.left ~= saved.left or
        current.right ~= saved.right or current.bottom ~= saved.bottom
end
--@end-non-alpha@]===]
    --@alpha@
    if not self.dummyFrames then return false end
    local profile = self:GetActiveProfile()
    local saved = {
        top     = profile.top       or Constants.DEFAULT_TOP,
        left    = profile.left      or Constants.DEFAULT_LEFT,
        right   = profile.right     or Constants.DEFAULT_RIGHT,
        bottom  = profile.bottom    or Constants.DEFAULT_BOTTOM,
    }
    local current = {
        top     = self.dummyFrames.top:GetHeight(),
        left    = self.dummyFrames.left:GetWidth(),
        right   = self.dummyFrames.right:GetWidth(),
        bottom  = self.dummyFrames.bottom:GetHeight(),
    }
    return current.top ~= saved.top
        or current.left ~= saved.left
        or current.right ~= saved.right
        or current.bottom ~= saved.bottom
end
    --@end-alpha@

-- Function to hide dummy frames upon menu close
function AuralinVP:OnMenuClose()
    if self:ChangesDetected() then
        StaticPopupDialogs["AURALIN_UNSAVED_CHANGES"] = {
            text        = "You have unsaved changes. \nSave & Reload or Cancel to discard changes.",
            button1     = "Save & Reload",
            button2     = "Cancel",
            OnAccept    = function()
                --[===[@non-alpha@
                Auralin_Viewport_Settings = {
                    top     = math.floor(self.dummyFrames.top:GetHeight()       + Constants.ROUNDING_THRESHOLD),
                    left    = math.floor(self.dummyFrames.left:GetWidth()       + Constants.ROUNDING_THRESHOLD),
                    right   = math.floor(self.dummyFrames.right:GetWidth()      + Constants.ROUNDING_THRESHOLD),
                    bottom  = math.floor(self.dummyFrames.bottom:GetHeight()    + Constants.ROUNDING_THRESHOLD),
                }
                --@end-non-alpha@]===]
                --@alpha@
                local profile = self:GetActiveProfile()
                profile.top     = math.floor(self.dummyFrames.top:GetHeight()       + Constants.ROUNDING_THRESHOLD)
                profile.left    = math.floor(self.dummyFrames.left:GetWidth()       + Constants.ROUNDING_THRESHOLD)
                profile.right   = math.floor(self.dummyFrames.right:GetWidth()      + Constants.ROUNDING_THRESHOLD)
                profile.bottom  = math.floor(self.dummyFrames.bottom:GetHeight()    + Constants.ROUNDING_THRESHOLD)
                --@end-alpha@
                ReloadUI()
            end,
            --[===[@non-alpha@
            OnCancel       = function()
                local top    = Auralin_Viewport_Settings.top or Constants.DEFAULT_TOP
                local bottom = Auralin_Viewport_Settings.bottom or Constants.DEFAULT_BOTTOM
                local left   = Auralin_Viewport_Settings.left or Constants.DEFAULT_LEFT
                local right  = Auralin_Viewport_Settings.right or Constants.DEFAULT_RIGHT
            --@end-non-alpha@]===]
            --@alpha@
            OnCancel       = function()
                local profile = self:GetActiveProfile()
                local top    = profile.top      or Constants.DEFAULT_TOP
                local left   = profile.left     or Constants.DEFAULT_LEFT
                local right  = profile.right    or Constants.DEFAULT_RIGHT
                local bottom = profile.bottom   or Constants.DEFAULT_BOTTOM
            --@end-alpha@
                -- Reset dummy frames
                if AuralinVP.dummyFrames then
                    self:ResetDummyFrame(AuralinVP.dummyFrames.top, {
                        { "TOPLEFT", nil, "TOPLEFT", 0, 0 },
                        { "TOPRIGHT", nil, "TOPRIGHT", 0, 0 },
                    }, { height = top })
                    self:ResetDummyFrame(AuralinVP.dummyFrames.bottom, {
                        { "BOTTOMLEFT", nil, "BOTTOMLEFT", 0, 0 },
                        { "BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, 0 },
                    }, { height = bottom })
                    self:ResetDummyFrame(AuralinVP.dummyFrames.left, {
                        { "TOPLEFT", nil, "TOPLEFT", 0, -top },
                        { "BOTTOMLEFT", nil, "BOTTOMLEFT", 0, bottom },
                    }, { width = left })
                    self:ResetDummyFrame(AuralinVP.dummyFrames.right, {
                        { "TOPRIGHT", nil, "TOPRIGHT", 0, -top },
                        { "BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, bottom },
                    }, { width = right })
                end

                self:RestoreWorldFrame(left, top, right, bottom)
                self:DestroyDummyFrames()
                if AuralinVP.MainMenuFrame then
                    AuralinVP.MainMenuFrame:Hide()
                end
            end,



            timeout         = 0,
            whileDead       = true,
            hideOnEscape    = true,
            preferredIndex  = 3,
        }
        StaticPopup_Show("AURALIN_UNSAVED_CHANGES")
    else
        -- No changes detected; clean up
        self:DestroyDummyFrames()
    end
end

AuralinVP.MainMenuFrame = CreateFrame("Frame", "MainMenuFrame", UIParent, "BasicFrameTemplateWithInset")
AuralinVP.MainMenuFrame:SetScript("OnHide", function() AuralinVP:OnMenuClose() end)
AuralinVP.MainMenuFrame:SetSize(600, 400)
AuralinVP.MainMenuFrame:SetPoint("CENTER")
AuralinVP.MainMenuFrame:Hide()

-- Add title
AuralinVP.MainMenuFrame.title = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
AuralinVP.MainMenuFrame.title:SetFontObject("GameFontHighlight")
AuralinVP.MainMenuFrame.title:SetPoint("LEFT", AuralinVP.MainMenuFrame.TitleBg, "LEFT", 5, 0)
AuralinVP.MainMenuFrame.title:SetText("Auralin Viewport")

function AuralinVP:InitializeMenu()
    local frame = self.MainMenuFrame


    -- Add Save & Reload button
    local button = CreateFrame("Button", "SaveButtonName", frame, "UIPanelButtonTemplate")
    button:SetSize(100, 22)
    button:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    button:SetText("Save & Reload")
    button:SetScript("OnClick", function()
        if self.dummyFrames then
            --[===[@non-alpha@
            Auralin_Viewport_Settings = {
                top     = self.dummyFrames.top:GetHeight(),
                left    = self.dummyFrames.left:GetWidth(),
                right   = self.dummyFrames.right:GetWidth(),
                bottom  = self.dummyFrames.bottom:GetHeight(),
            }
            --@end-non-alpha@]===]
            --@alpha@
            local profile = self:GetActiveProfile()
            profile.top     = math.floor(self.dummyFrames.top:GetHeight()      + Constants.ROUNDING_THRESHOLD)
            profile.left    = math.floor(self.dummyFrames.left:GetWidth()      + Constants.ROUNDING_THRESHOLD)
            profile.right   = math.floor(self.dummyFrames.right:GetWidth()     + Constants.ROUNDING_THRESHOLD)
            profile.bottom  = math.floor(self.dummyFrames.bottom:GetHeight()   + Constants.ROUNDING_THRESHOLD)
            --@end-alpha@
            ReloadUI()
        else
            print("Error: Dummy frames not initialized.")
        end
    end)
end

AuralinVP:InitializeMenu()

AuralinVP.topSlider, AuralinVP.leftSlider, AuralinVP.rightSlider, AuralinVP.bottomSlider = nil, nil, nil, nil
AuralinVP.dummyFrames = nil -- Store references to dummy frames
