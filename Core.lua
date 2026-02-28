local addonName, AuralinVP = ...

AuralinVP = AuralinVP or {}
AuralinVP.Constants = {
    DEFAULT_TOP = 0,
    DEFAULT_BOTTOM = 112,
    DEFAULT_LEFT = 0,
    DEFAULT_RIGHT = 0,
    DEFAULT_PROFILE_NAME = "Default",
    ROUNDING_THRESHOLD = 0.5,
    MAX_SLIDER_VALUE = 500,
    DEFAULT_SLIDER_LENGTH = 200,
    PROFILE_SCHEMA_VERSION = 2,
    MAX_PROFILE_NAME_LENGTH = 32,
}

local Constants = AuralinVP.Constants
local tUnpack = table.unpack or unpack
local floor = math.floor
local type = type
local tinsert = table.insert

local function RoundViewportValue(value)
    return floor((tonumber(value) or 0) + Constants.ROUNDING_THRESHOLD)
end

function AuralinVP:GetFrameScale(frame)
    if frame and frame.GetEffectiveScale then
        local scale = frame:GetEffectiveScale()
        if scale and scale > 0 then
            return scale
        end
    end

    return 1
end

function AuralinVP:ConvertWorldUnitsToPreviewUnits(value)
    local worldScale = self:GetFrameScale(WorldFrame)
    local uiScale = self:GetFrameScale(UIParent)
    return (tonumber(value) or 0) * (worldScale / uiScale)
end

function AuralinVP:ConvertPreviewUnitsToWorldUnits(value)
    local worldScale = self:GetFrameScale(WorldFrame)
    local uiScale = self:GetFrameScale(UIParent)
    return (tonumber(value) or 0) * (uiScale / worldScale)
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
local function GetCurrentTimestamp()
    if type(time) == "function" then
        return time()
    end

    return 0
end

local function CopyProfileSettings(source)
    return {
        top = tonumber(source and source.top) or Constants.DEFAULT_TOP,
        left = tonumber(source and source.left) or Constants.DEFAULT_LEFT,
        right = tonumber(source and source.right) or Constants.DEFAULT_RIGHT,
        bottom = tonumber(source and source.bottom) or Constants.DEFAULT_BOTTOM,
    }
end

function AuralinVP:GetCharacterFullName()
    local name, realm = UnitName("player")
    if not name or name == "" then
        return nil
    end

    if not realm or realm == "" then
        realm = GetNormalizedRealmName() or GetRealmName() or "UnknownRealm"
    end

    return realm .. "-" .. name
end

function AuralinVP:GetCurrentCharacterKey()
    return self:GetCharacterFullName()
end

function AuralinVP:GetProfileStorage()
    if type(Auralin_Viewport_Profiles) == "table" then
        return Auralin_Viewport_Profiles
    end

    return nil
end

function AuralinVP:GetProfileMeta()
    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" then
        return nil
    end

    if type(profileStore.meta) ~= "table" then
        profileStore.meta = {}
    end

    local meta = profileStore.meta
    if type(meta.createdAtByProfile) ~= "table" then
        meta.createdAtByProfile = {}
    end
    if type(meta.updatedAtByProfile) ~= "table" then
        meta.updatedAtByProfile = {}
    end

    if type(meta.schemaVersion) ~= "number" or meta.schemaVersion < Constants.PROFILE_SCHEMA_VERSION then
        meta.schemaVersion = Constants.PROFILE_SCHEMA_VERSION
    end

    return meta
end

function AuralinVP:TouchProfileMetadata(profileName, isCreate)
    local meta = self:GetProfileMeta()
    local normalizedProfileName = self:NormalizeProfileName(profileName)
    if not meta or normalizedProfileName == "" then
        return
    end

    local timestamp = GetCurrentTimestamp()
    if isCreate and meta.createdAtByProfile[normalizedProfileName] == nil then
        meta.createdAtByProfile[normalizedProfileName] = timestamp
    end

    meta.updatedAtByProfile[normalizedProfileName] = timestamp
end

function AuralinVP:NormalizeProfileName(profileName)
    if profileName == nil then
        return ""
    end

    local normalized = tostring(profileName)
    if type(strtrim) == "function" then
        normalized = strtrim(normalized)
    else
        normalized = normalized:gsub("^%s+", ""):gsub("%s+$", "")
    end

    return normalized
end

function AuralinVP:IsDefaultProfile(profileName)
    return self:NormalizeProfileName(profileName) == Constants.DEFAULT_PROFILE_NAME
end

function AuralinVP:ValidateProfileName(profileName, options)
    options = options or {}

    local normalized = self:NormalizeProfileName(profileName)
    if normalized == "" then
        return nil, "Profile name cannot be empty."
    end

    if #normalized > Constants.MAX_PROFILE_NAME_LENGTH then
        return nil, "Profile name cannot exceed " .. Constants.MAX_PROFILE_NAME_LENGTH .. " characters."
    end

    if normalized:find("[%c]") then
        return nil, "Profile name cannot contain control characters."
    end

    if options.forCreate and self:IsDefaultProfile(normalized) then
        return nil, "The profile name '" .. Constants.DEFAULT_PROFILE_NAME .. "' is reserved."
    end

    return normalized
end

function AuralinVP:RefreshProfileState()
    if self.UpdateProfileLabel then
        self:UpdateProfileLabel()
    end

    if self.RefreshProfileDropDown then
        self:RefreshProfileDropDown()
    end

    if self.UpdateSlidersWithCurrentSettings then
        self:UpdateSlidersWithCurrentSettings()
    end

    if self.ApplyViewportSettings then
        self:ApplyViewportSettings()
    end
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

    local charKey = self:GetCurrentCharacterKey()
    if not charKey then
        return nil
    end

    local assignedProfile = self:NormalizeProfileName(charSettings[charKey])
    if assignedProfile == "" then
        assignedProfile = nil
    end

    if assignedProfile and not profiles[assignedProfile] then
        charSettings[charKey] = nil
        assignedProfile = nil
    end

    if not assignedProfile and profiles[Constants.DEFAULT_PROFILE_NAME] then
        charSettings[charKey] = Constants.DEFAULT_PROFILE_NAME
        assignedProfile = Constants.DEFAULT_PROFILE_NAME
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

        if Auralin_Viewport_Profiles.profiles[Constants.DEFAULT_PROFILE_NAME] then
            return Auralin_Viewport_Profiles.profiles[Constants.DEFAULT_PROFILE_NAME]
        end
    end

    return CopyProfileSettings(nil)
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

function AuralinVP:GetCharactersUsingProfile(profileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local normalizedProfileName = self:NormalizeProfileName(profileName)
    if normalizedProfileName == "" or type(Auralin_Viewport_Profiles) ~= "table" or type(Auralin_Viewport_Profiles.charSettings) ~= "table" then
        return {}
    end

    local characters = {}
    for charKey, assignedProfile in pairs(Auralin_Viewport_Profiles.charSettings) do
        if assignedProfile == normalizedProfileName then
            tinsert(characters, charKey)
        end
    end
    table.sort(characters)
    return characters
end

function AuralinVP:AssignProfileToCharacter(charKey, profileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local normalizedCharKey = charKey or self:GetCurrentCharacterKey()
    if normalizedCharKey ~= nil then
        normalizedCharKey = tostring(normalizedCharKey)
        if type(strtrim) == "function" then
            normalizedCharKey = strtrim(normalizedCharKey)
        else
            normalizedCharKey = normalizedCharKey:gsub("^%s+", ""):gsub("%s+$", "")
        end
    end

    if not normalizedCharKey then
        return false, "Cannot assign profile; character name is unavailable."
    end
    if normalizedCharKey == "" then
        return false, "Cannot assign profile; character key cannot be empty."
    end

    local normalizedProfileName, errorMessage = self:ValidateProfileName(profileName)
    if not normalizedProfileName then
        return false, errorMessage
    end

    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" or type(profileStore.profiles) ~= "table" then
        return false, "Cannot assign profile; profile storage is unavailable."
    end

    if not profileStore.profiles[normalizedProfileName] then
        if profileStore.profiles[Constants.DEFAULT_PROFILE_NAME] then
            normalizedProfileName = Constants.DEFAULT_PROFILE_NAME
        else
            return false, "Cannot assign profile; profile does not exist: " .. tostring(profileName)
        end
    end

    profileStore.charSettings = profileStore.charSettings or {}
    profileStore.charSettings[normalizedCharKey] = normalizedProfileName

    if normalizedCharKey == self:GetCurrentCharacterKey() then
        self:RefreshProfileState()
    elseif self.UpdateProfileLabel then
        self:UpdateProfileLabel()
    end

    return true, normalizedProfileName
end

function AuralinVP:SetActiveProfile(profileName)
    local success, result = self:AssignProfileToCharacter(self:GetCurrentCharacterKey(), profileName)
    if not success then
        self:Print(result)
        return false, result
    end

    return true, result
end

function AuralinVP:CreateProfile(profileName, sourceProfileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local normalizedProfileName, errorMessage = self:ValidateProfileName(profileName, { forCreate = true })
    if not normalizedProfileName then
        return false, errorMessage
    end

    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" or type(profileStore.profiles) ~= "table" then
        return false, "Cannot create profile; profile storage is unavailable."
    end

    if profileStore.profiles[normalizedProfileName] then
        return false, "Profile '" .. normalizedProfileName .. "' already exists."
    end

    local sourceSettings = nil
    if sourceProfileName ~= nil then
        local normalizedSourceName, sourceError = self:ValidateProfileName(sourceProfileName)
        if not normalizedSourceName then
            return false, sourceError
        end

        sourceSettings = profileStore.profiles[normalizedSourceName]
        if not sourceSettings then
            return false, "Cannot create profile; source profile does not exist: " .. tostring(sourceProfileName)
        end
    else
        sourceSettings = self.GetStoredSettings and self:GetStoredSettings() or self:GetActiveProfile()
    end

    profileStore.profiles[normalizedProfileName] = CopyProfileSettings(sourceSettings)
    self:TouchProfileMetadata(normalizedProfileName, true)

    return true, normalizedProfileName
end

function AuralinVP:CopyProfile(sourceProfileName, targetProfileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local sourceName, sourceError = self:ValidateProfileName(sourceProfileName)
    if not sourceName then
        return false, sourceError
    end

    local targetName, targetError = self:ValidateProfileName(targetProfileName)
    if not targetName then
        return false, targetError
    end

    if sourceName == targetName then
        return false, "Cannot copy profile; source and target are the same."
    end

    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" or type(profileStore.profiles) ~= "table" then
        return false, "Cannot copy profile; profile storage is unavailable."
    end

    if not profileStore.profiles[sourceName] then
        return false, "Cannot copy profile; source profile does not exist: " .. tostring(sourceName)
    end

    if not profileStore.profiles[targetName] then
        return false, "Cannot copy profile; target profile does not exist: " .. tostring(targetName)
    end

    profileStore.profiles[targetName] = CopyProfileSettings(profileStore.profiles[sourceName])
    self:TouchProfileMetadata(targetName, false)

    if self:GetActiveProfileName() == targetName then
        self:RefreshProfileState()
    end

    return true, targetName
end

function AuralinVP:RenameProfile(oldName, newName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local normalizedOldName, oldError = self:ValidateProfileName(oldName)
    if not normalizedOldName then
        return false, oldError
    end

    if self:IsDefaultProfile(normalizedOldName) then
        return false, "Cannot rename the '" .. Constants.DEFAULT_PROFILE_NAME .. "' profile."
    end

    local normalizedNewName, newError = self:ValidateProfileName(newName, { forCreate = true })
    if not normalizedNewName then
        return false, newError
    end

    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" or type(profileStore.profiles) ~= "table" then
        return false, "Cannot rename profile; profile storage is unavailable."
    end

    if not profileStore.profiles[normalizedOldName] then
        return false, "Cannot rename profile; profile does not exist: " .. tostring(normalizedOldName)
    end

    if profileStore.profiles[normalizedNewName] then
        return false, "Cannot rename profile; '" .. normalizedNewName .. "' already exists."
    end

    profileStore.profiles[normalizedNewName] = profileStore.profiles[normalizedOldName]
    profileStore.profiles[normalizedOldName] = nil

    local meta = self:GetProfileMeta()
    if meta then
        if meta.createdAtByProfile[normalizedOldName] ~= nil then
            meta.createdAtByProfile[normalizedNewName] = meta.createdAtByProfile[normalizedOldName]
            meta.createdAtByProfile[normalizedOldName] = nil
        end

        if meta.updatedAtByProfile[normalizedOldName] ~= nil then
            meta.updatedAtByProfile[normalizedNewName] = meta.updatedAtByProfile[normalizedOldName]
            meta.updatedAtByProfile[normalizedOldName] = nil
        end
    end

    if type(profileStore.charSettings) == "table" then
        for charKey, assignedProfile in pairs(profileStore.charSettings) do
            if assignedProfile == normalizedOldName then
                profileStore.charSettings[charKey] = normalizedNewName
            end
        end
    end

    self:TouchProfileMetadata(normalizedNewName, false)
    self:RefreshProfileState()
    return true, normalizedNewName
end

function AuralinVP:DeleteProfile(profileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local normalizedProfileName, errorMessage = self:ValidateProfileName(profileName)
    if not normalizedProfileName then
        return false, errorMessage
    end

    if self:IsDefaultProfile(normalizedProfileName) then
        return false, "Cannot delete the '" .. Constants.DEFAULT_PROFILE_NAME .. "' profile."
    end

    if self:GetActiveProfileName() == normalizedProfileName then
        return false, "Cannot delete the active profile '" .. normalizedProfileName .. "'."
    end

    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" or type(profileStore.profiles) ~= "table" then
        return false, "Cannot delete profile; profile storage is unavailable."
    end

    if not profileStore.profiles[normalizedProfileName] then
        return false, "Cannot delete profile; profile does not exist: " .. tostring(normalizedProfileName)
    end

    profileStore.profiles[normalizedProfileName] = nil

    local meta = self:GetProfileMeta()
    if meta then
        meta.createdAtByProfile[normalizedProfileName] = nil
        meta.updatedAtByProfile[normalizedProfileName] = nil
    end

    local reassignedCount = 0
    profileStore.charSettings = profileStore.charSettings or {}
    for charKey, assignedProfile in pairs(profileStore.charSettings) do
        if assignedProfile == normalizedProfileName then
            profileStore.charSettings[charKey] = Constants.DEFAULT_PROFILE_NAME
            reassignedCount = reassignedCount + 1
        end
    end

    self:RefreshProfileState()
    return true, reassignedCount
end

function AuralinVP:ResetProfile(profileName)
    if self.EnsureProfileStorage then
        self:EnsureProfileStorage()
    end

    local normalizedProfileName, errorMessage = self:ValidateProfileName(profileName)
    if not normalizedProfileName then
        return false, errorMessage
    end

    local profileStore = self:GetProfileStorage()
    if type(profileStore) ~= "table" or type(profileStore.profiles) ~= "table" then
        return false, "Cannot reset profile; profile storage is unavailable."
    end

    if not profileStore.profiles[normalizedProfileName] then
        return false, "Cannot reset profile; profile does not exist: " .. tostring(normalizedProfileName)
    end

    profileStore.profiles[normalizedProfileName] = CopyProfileSettings(nil)
    self:TouchProfileMetadata(normalizedProfileName, false)

    if self:GetActiveProfileName() == normalizedProfileName then
        self:RefreshProfileState()
    end

    return true, normalizedProfileName
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
        top = RoundViewportValue(self:ConvertPreviewUnitsToWorldUnits(self.dummyFrames.top and self.dummyFrames.top:GetHeight())),
        left = RoundViewportValue(self:ConvertPreviewUnitsToWorldUnits(self.dummyFrames.left and self.dummyFrames.left:GetWidth())),
        right = RoundViewportValue(self:ConvertPreviewUnitsToWorldUnits(self.dummyFrames.right and self.dummyFrames.right:GetWidth())),
        bottom = RoundViewportValue(self:ConvertPreviewUnitsToWorldUnits(self.dummyFrames.bottom and self.dummyFrames.bottom:GetHeight())),
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
    local topPreview = self:ConvertWorldUnitsToPreviewUnits(top)
    local bottomPreview = self:ConvertWorldUnitsToPreviewUnits(bottom)
    local leftPreview = self:ConvertWorldUnitsToPreviewUnits(left)
    local rightPreview = self:ConvertWorldUnitsToPreviewUnits(right)

    self:ResetDummyFrame(self.dummyFrames.top, {
        { "TOPLEFT", UIParent, "TOPLEFT", 0, 0 },
        { "TOPRIGHT", UIParent, "TOPRIGHT", 0, 0 },
    }, { height = topPreview })

    self:ResetDummyFrame(self.dummyFrames.bottom, {
        { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0 },
        { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0 },
    }, { height = bottomPreview })

    self:ResetDummyFrame(self.dummyFrames.left, {
        { "TOPLEFT", UIParent, "TOPLEFT", 0, -topPreview },
        { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottomPreview },
    }, { width = leftPreview })

    self:ResetDummyFrame(self.dummyFrames.right, {
        { "TOPRIGHT", UIParent, "TOPRIGHT", 0, -topPreview },
        { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, bottomPreview },
    }, { width = rightPreview })
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

StaticPopupDialogs["AURALIN_VIEWPORT_DELETE_PROFILE_CONFIRM"] = StaticPopupDialogs["AURALIN_VIEWPORT_DELETE_PROFILE_CONFIRM"] or {
    text = "Delete profile '%s'?\nCharacters using it will be reassigned to Default.",
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(_, profileName)
        if not AuralinVP.DeleteProfile then
            return
        end

        local success, result = AuralinVP:DeleteProfile(profileName)
        if not success then
            AuralinVP:Print(result or "Unable to delete profile.")
            return
        end

        AuralinVP:Print("Deleted profile '" .. tostring(profileName) .. "'. Reassigned " .. tostring(result or 0) .. " character(s) to Default.")
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
