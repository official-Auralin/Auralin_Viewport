local addonName, AuralinVP = ...
local Constants = AuralinVP.Constants

local floor = math.floor
local max = math.max
local type = type

local SETTING_KEYS = { "top", "left", "right", "bottom" }

local function SanitizeViewportValue(value, defaultValue)
    local numericValue = tonumber(value)
    if numericValue == nil then
        numericValue = defaultValue
    end

    return max(0, floor(numericValue + Constants.ROUNDING_THRESHOLD))
end

local function SanitizeSettingsTable(tbl)
    for _, key in ipairs(SETTING_KEYS) do
        local defaultValue = Constants["DEFAULT_" .. key:upper()]
        tbl[key] = SanitizeViewportValue(tbl[key], defaultValue)
    end

    return tbl
end

local function CopySanitizedSettingsFromTable(source, target)
    target = target or {}

    for _, key in ipairs(SETTING_KEYS) do
        local defaultValue = Constants["DEFAULT_" .. key:upper()]
        target[key] = SanitizeViewportValue(source and source[key], defaultValue)
    end

    return target
end

function AuralinVP:EnsureLegacySettings()
    if type(Auralin_Viewport_Settings) ~= "table" then
        Auralin_Viewport_Settings = {}
    end

    return SanitizeSettingsTable(Auralin_Viewport_Settings)
end

--@alpha@
function AuralinVP:EnsureProfileStorage()
    local legacySettings = self:EnsureLegacySettings()

    if type(Auralin_Viewport_Profiles) ~= "table" then
        Auralin_Viewport_Profiles = {}
    end

    local profileStore = Auralin_Viewport_Profiles
    if type(profileStore.profiles) ~= "table" then
        profileStore.profiles = {}
    end
    if type(profileStore.charSettings) ~= "table" then
        profileStore.charSettings = {}
    end
    if type(profileStore.meta) ~= "table" then
        profileStore.meta = {}
    end

    local hadDefaultProfile = profileStore.profiles.Default ~= nil
    profileStore.profiles.Default = CopySanitizedSettingsFromTable(profileStore.profiles.Default, profileStore.profiles.Default)

    if profileStore.meta.legacyImported ~= true then
        if not hadDefaultProfile then
            CopySanitizedSettingsFromTable(legacySettings, profileStore.profiles.Default)
        end
        profileStore.meta.legacyImported = true
    end

    local activeProfileName = self:GetActiveProfileName()
    if not activeProfileName and profileStore.profiles.Default then
        local charName, charRealm = UnitName("player")
        if charName and charName ~= "" then
            local normalizedRealm = charRealm
            if not normalizedRealm or normalizedRealm == "" then
                normalizedRealm = GetNormalizedRealmName() or GetRealmName() or "UnknownRealm"
            end
            profileStore.charSettings[normalizedRealm .. "-" .. charName] = "Default"
        end
    end

    return profileStore
end
--@end-alpha@

--[===[@non-alpha@
function AuralinVP:EnsureProfileStorage()
    return nil
end
--@end-non-alpha@]===]

function AuralinVP:InitializePersistentData()
    self:EnsureLegacySettings()
    --@alpha@
    self:EnsureProfileStorage()
    --@end-alpha@
end

--@alpha@
function AuralinVP:GetStoredSettingsTable()
    self:EnsureProfileStorage()
    return self:GetActiveProfile()
end
--@end-alpha@

--[===[@non-alpha@
function AuralinVP:GetStoredSettingsTable()
    return self:EnsureLegacySettings()
end
--@end-non-alpha@]===]

function AuralinVP:GetStoredSettings()
    local source = self:GetStoredSettingsTable()
    return CopySanitizedSettingsFromTable(source, {})
end

function AuralinVP:SetStoredSettings(settings)
    local target = self:GetStoredSettingsTable()
    return CopySanitizedSettingsFromTable(settings, target)
end

function AuralinVP:GetCurrentSettings()
    return self:GetStoredSettings()
end

function AuralinVP:UpdateSlidersWithCurrentSettings()
    local settings = self:GetStoredSettings()
    local sliderMappings = {
        { self.topSlider, settings.top },
        { self.leftSlider, settings.left },
        { self.rightSlider, settings.right },
        { self.bottomSlider, settings.bottom },
    }

    self.isSyncingSliders = true
    for _, mapping in ipairs(sliderMappings) do
        local slider = mapping[1]
        local value = mapping[2]

        if slider then
            slider:SetValue(value)

            if slider.value then
                slider.value:SetText(value)
            end

            if slider.editBox then
                slider.editBox:SetText(value)
            end
        end
    end
    self.isSyncingSliders = nil

    --@alpha@
    if self.UpdateProfileLabel then
        self:UpdateProfileLabel()
    end
    --@end-alpha@

    return settings
end
