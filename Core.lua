local addonName, AuralinVP = ...

AuralinVP = AuralinVP or {}
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
local tUnpack = table.unpack or unpack
local floor = math.floor
local type = type
local tinsert = table.insert

local function RoundViewportValue(value)
    return floor((tonumber(value) or 0) + Constants.ROUNDING_THRESHOLD)
end

function AuralinVP:Print(message)
    print("Auralin_Viewport: " .. tostring(message))
end

function AuralinVP:GetScreenDimensions()
    if type(GetPhysicalScreenSize) == "function" then
        local width, height = GetPhysicalScreenSize()
        if width and height and width > 0 and height > 0 then
            return width, height
        end
    end

    if type(GetScreenWidth) == "function" and type(GetScreenHeight) == "function" then
        local width = GetScreenWidth()
        local height = GetScreenHeight()
        if width and height and width > 0 and height > 0 then
            return width, height
        end
    end

    return UIParent:GetWidth() or 0, UIParent:GetHeight() or 0
end

function AuralinVP:ResetDummyFrame(frame, points, size)
    if not frame then
        return
    end

    frame:ClearAllPoints()
    for _, point in ipairs(points) do
        frame:SetPoint(tUnpack(point))
    end

    if size.width then
        frame:SetWidth(size.width)
    end

    if size.height then
        frame:SetHeight(size.height)
    end
end

function AuralinVP:RestoreWorldFrame(left, top, right, bottom)
    WorldFrame:ClearAllPoints()
    WorldFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left or 0, -(top or 0))
    WorldFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -(right or 0), bottom or 0)
end

--@alpha@
local function GetCharacterFullName()
    local name, realm = UnitName("player")
    if not name or name == "" then
        return nil
    end

    if not realm or realm == "" then
        realm = GetNormalizedRealmName() or GetRealmName() or "UnknownRealm"
    end

    return realm .. "-" .. name
end

function AuralinVP:GetActiveProfileName()
    if type(Auralin_Viewport_Profiles) ~= "table" then
        return nil
    end

    local profiles = Auralin_Viewport_Profiles.profiles
    local charSettings = Auralin_Viewport_Profiles.charSettings
    if type(profiles) ~= "table" or type(charSettings) ~= "table" then
        return nil
    end

    local charKey = GetCharacterFullName()
    if not charKey then
        return nil
    end

    local assignedProfile = charSettings[charKey]
    if assignedProfile and not profiles[assignedProfile] then
        charSettings[charKey] = nil
        assignedProfile = nil
    end

    if not assignedProfile and profiles.Default then
        charSettings[charKey] = "Default"
        assignedProfile = "Default"
    end

    return assignedProfile
end

function AuralinVP:GetActiveProfile()
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    if type(Auralin_Viewport_Profiles) == "table" and type(Auralin_Viewport_Profiles.profiles) == "table" then
        local profileName = self:GetActiveProfileName()
        local profile = profileName and Auralin_Viewport_Profiles.profiles[profileName]
        if profile then
            return profile
        end

        if Auralin_Viewport_Profiles.profiles.Default then
            return Auralin_Viewport_Profiles.profiles.Default
        end
    end

    return {
        top = Constants.DEFAULT_TOP,
        left = Constants.DEFAULT_LEFT,
        right = Constants.DEFAULT_RIGHT,
        bottom = Constants.DEFAULT_BOTTOM,
    }
end

function AuralinVP:GetAvailableProfiles()
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    if type(Auralin_Viewport_Profiles) ~= "table" or type(Auralin_Viewport_Profiles.profiles) ~= "table" then
        return {}
    end

    local list = {}
    for profileName in pairs(Auralin_Viewport_Profiles.profiles) do
        tinsert(list, profileName)
    end
    table.sort(list)
    return list
end

function AuralinVP:SetActiveProfile(profileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    if not profileName or type(Auralin_Viewport_Profiles) ~= "table" or type(Auralin_Viewport_Profiles.profiles) ~= "table" then
        self:Print("Cannot set active profile; profile storage is unavailable.")
        return
    end

    if not Auralin_Viewport_Profiles.profiles[profileName] then
        self:Print("Cannot set active profile; profile does not exist: " .. tostring(profileName))
        return
    end

    local charKey = GetCharacterFullName()
    if not charKey then
        self:Print("Cannot set active profile; character name is unavailable.")
        return
    end

    Auralin_Viewport_Profiles.charSettings = Auralin_Viewport_Profiles.charSettings or {}
    Auralin_Viewport_Profiles.charSettings[charKey] = profileName

    if self.UpdateProfileLabel then
        self:UpdateProfileLabel()
    end

    if self.UpdateSlidersWithCurrentSettings then
        self:UpdateSlidersWithCurrentSettings()
    end
end
--@end-alpha@

--[===[@non-alpha@
function AuralinVP:GetSettingOrDefault(key)
    local defaultsKey = "DEFAULT_" .. key:upper()
    if type(Auralin_Viewport_Settings) == "table" and Auralin_Viewport_Settings[key] ~= nil then
        return Auralin_Viewport_Settings[key]
    end
    return Constants[defaultsKey]
end
--@end-non-alpha@]===]

function AuralinVP:GetRoundedDummyFrameSettings()
    if not self.dummyFrames then
        return nil
    end

    return {
        top = RoundViewportValue(self.dummyFrames.top and self.dummyFrames.top:GetHeight()),
        left = RoundViewportValue(self.dummyFrames.left and self.dummyFrames.left:GetWidth()),
        right = RoundViewportValue(self.dummyFrames.right and self.dummyFrames.right:GetWidth()),
        bottom = RoundViewportValue(self.dummyFrames.bottom and self.dummyFrames.bottom:GetHeight()),
    }
end

function AuralinVP:DestroyDummyFrames()
    if not self.dummyFrames then
        return
    end

    for _, frame in pairs(self.dummyFrames) do
        frame:Hide()
    end
end

function AuralinVP:ChangesDetected()
    local current = self:GetRoundedDummyFrameSettings()
    if not current or not self.GetStoredSettings then
        return false
    end

    local saved = self:GetStoredSettings()
    return current.top ~= saved.top
        or current.left ~= saved.left
        or current.right ~= saved.right
        or current.bottom ~= saved.bottom
end

function AuralinVP:RestoreDummyFramesToStoredSettings()
    if not self.dummyFrames or not self.GetStoredSettings then
        return
    end

    local settings = self:GetStoredSettings()
    local top = settings.top or Constants.DEFAULT_TOP
    local bottom = settings.bottom or Constants.DEFAULT_BOTTOM
    local left = settings.left or Constants.DEFAULT_LEFT
    local right = settings.right or Constants.DEFAULT_RIGHT

    self:ResetDummyFrame(self.dummyFrames.top, {
        { "TOPLEFT", UIParent, "TOPLEFT", 0, 0 },
        { "TOPRIGHT", UIParent, "TOPRIGHT", 0, 0 },
    }, { height = top })

    self:ResetDummyFrame(self.dummyFrames.bottom, {
        { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0 },
        { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0 },
    }, { height = bottom })

    self:ResetDummyFrame(self.dummyFrames.left, {
        { "TOPLEFT", UIParent, "TOPLEFT", 0, -top },
        { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottom },
    }, { width = left })

    self:ResetDummyFrame(self.dummyFrames.right, {
        { "TOPRIGHT", UIParent, "TOPRIGHT", 0, -top },
        { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, bottom },
    }, { width = right })
end

function AuralinVP:PersistCurrentSettings()
    if not self.SetStoredSettings then
        return false
    end

    local settings = self:GetRoundedDummyFrameSettings()
    if not settings and self.GetCurrentSettings then
        settings = self:GetCurrentSettings()
    end
    if not settings then
        return false
    end

    self:SetStoredSettings(settings)
    return true
end

function AuralinVP:SaveAndReload()
    if not self:PersistCurrentSettings() then
        self:Print("Unable to save current settings.")
        return
    end

    self.suppressClosePrompt = true
    ReloadUI()
end

StaticPopupDialogs["AURALIN_VIEWPORT_UNSAVED_CHANGES"] = StaticPopupDialogs["AURALIN_VIEWPORT_UNSAVED_CHANGES"] or {
    text = "You have unsaved changes.\nSave & Reload or Cancel to discard changes.",
    button1 = "Save & Reload",
    button2 = "Cancel",
    OnAccept = function()
        AuralinVP:SaveAndReload()
    end,
    OnCancel = function()
        if not AuralinVP.GetStoredSettings then
            AuralinVP:DestroyDummyFrames()
            return
        end

        local settings = AuralinVP:GetStoredSettings()
        AuralinVP:RestoreDummyFramesToStoredSettings()
        AuralinVP:RestoreWorldFrame(settings.left, settings.top, settings.right, settings.bottom)
        AuralinVP:DestroyDummyFrames()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function AuralinVP:OnMenuClose()
    if self.suppressClosePrompt then
        self.suppressClosePrompt = nil
        self:DestroyDummyFrames()
        return
    end

    if self:ChangesDetected() then
        StaticPopup_Show("AURALIN_VIEWPORT_UNSAVED_CHANGES")
        return
    end

    self:DestroyDummyFrames()
end

local menuWidth = 300
--@alpha@
menuWidth = 600
--@end-alpha@

AuralinVP.MainMenuFrame = CreateFrame("Frame", "AuralinVP_MainMenuFrame", UIParent, "BasicFrameTemplateWithInset")
AuralinVP.MainMenuFrame:SetScript("OnHide", function()
    AuralinVP:OnMenuClose()
end)
AuralinVP.MainMenuFrame:SetSize(menuWidth, 400)
AuralinVP.MainMenuFrame:SetPoint("CENTER")
AuralinVP.MainMenuFrame:SetClampedToScreen(true)
AuralinVP.MainMenuFrame:Hide()

AuralinVP.MainMenuFrame.title = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
AuralinVP.MainMenuFrame.title:SetFontObject("GameFontHighlight")
AuralinVP.MainMenuFrame.title:SetPoint("LEFT", AuralinVP.MainMenuFrame.TitleBg, "LEFT", 5, 0)
AuralinVP.MainMenuFrame.title:SetText("Auralin Viewport")

if UISpecialFrames and AuralinVP.MainMenuFrame:GetName() then
    tinsert(UISpecialFrames, AuralinVP.MainMenuFrame:GetName())
end

AuralinVP.topSlider = nil
AuralinVP.leftSlider = nil
AuralinVP.rightSlider = nil
AuralinVP.bottomSlider = nil
AuralinVP.dummyFrames = nil
