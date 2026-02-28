local addonName, AuralinVP = ...
local Constants = AuralinVP.Constants

local tUnpack = table.unpack or unpack
local max = math.max
local min = math.min
local floor = math.floor
local type = type

local function ClampViewportValue(rawValue, isVertical)
    local screenWidth, screenHeight = AuralinVP:GetScreenDimensions()
    local maxDimension = isVertical and screenHeight or screenWidth

    if not maxDimension or maxDimension <= 0 then
        maxDimension = Constants.MAX_SLIDER_VALUE * 2
    end

    local clampedValue = min(rawValue or 0, Constants.MAX_SLIDER_VALUE, maxDimension / 2)
    return floor(max(0, clampedValue) + Constants.ROUNDING_THRESHOLD)
end

local function CreateSlider(sliderName, parent, anchorPoint, labelText, minVal, maxVal, step, length)
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint(tUnpack(anchorPoint))
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(length or Constants.DEFAULT_SLIDER_LENGTH)

    local fsLabel = parent:CreateFontString(nil, "OVERLAY")
    fsLabel:SetPoint("LEFT", slider, "LEFT", 0, 15)
    fsLabel:SetFontObject("GameFontHighlight")
    fsLabel:SetText(labelText)
    slider.label = fsLabel

    local fsValue = slider:CreateFontString(nil, "OVERLAY")
    fsValue:SetPoint("BOTTOM", slider, "TOP", 0, 0)
    fsValue:SetFontObject("GameFontHighlight")
    slider.value = fsValue

    return slider
end

local function CreateViewportSlider(sliderName, parent, anchorPoint, labelText, minVal, maxVal, step, length, dimensionSetter, isVertical)
    local slider = CreateSlider(sliderName, parent, anchorPoint, labelText, minVal, maxVal, step, length)

    slider:SetScript("OnValueChanged", function(self, rawValue)
        local finalValue = ClampViewportValue(rawValue, isVertical)
        local previewValue = AuralinVP:ConvertWorldUnitsToPreviewUnits(finalValue)

        if self.value then
            self.value:SetText(finalValue)
        end

        if self.editBox and (not self.editBox:HasFocus()) then
            self.editBox:SetText(finalValue)
        end

        if AuralinVP.isSyncingSliders then
            return
        end

        if not AuralinVP.dummyFrames then
            AuralinVP:CreateDummyFrames()
        end

        if AuralinVP.dummyFrames then
            dimensionSetter(AuralinVP.dummyFrames, previewValue)

            if isVertical and AuralinVP.RefreshDummyFrameSideAnchors then
                AuralinVP:RefreshDummyFrameSideAnchors()
            end
        end
    end)

    return slider
end

local function CreateSliderInput(editBoxName, parent, anchorTo, slider)
    local editBox = CreateFrame("EditBox", editBoxName, parent, "InputBoxTemplate")
    editBox:SetSize(50, 20)
    editBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(5)
    editBox:SetNumeric(true)

    editBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value ~= nil then
            slider:SetValue(value)
        else
            self:SetText(slider:GetValue())
        end
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(slider:GetValue())
        self:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(slider:GetValue())
    end)

    slider.editBox = editBox
    return editBox
end

local background = AuralinVP.MainMenuFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(AuralinVP.MainMenuFrame)
background:SetColorTexture(0, 0, 0, 1)

local usageAnchorX = 20
--@alpha@
usageAnchorX = 155
--@end-alpha@

local usageLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
usageLabel:SetPoint("TOP", AuralinVP.MainMenuFrame, "TOPLEFT", usageAnchorX, -35)
usageLabel:SetFontObject("GameFontHighlight")
usageLabel:SetJustifyH("LEFT")
usageLabel:SetJustifyV("TOP")
usageLabel:SetText("This add-on adjusts the size of the frame\nused by the game client to render the\ngame-world. For changes to take place\nyou must 'Save & Reload'.")

--@alpha@
local verticalBar = AuralinVP.MainMenuFrame:CreateTexture(nil, "ARTWORK")
verticalBar:SetColorTexture(0.2, 0.2, 0.2, 0.8)
verticalBar:SetPoint("TOP", AuralinVP.MainMenuFrame, "TOP", 0, -35)
verticalBar:SetPoint("BOTTOM", AuralinVP.MainMenuFrame, "BOTTOM", 0, 40)
verticalBar:SetWidth(2)

function AuralinVP:UpdateProfileLabel()
    local currentProfileName = self:GetActiveProfileName() or "no profile assigned"
    if self.profileLabel then
        self.profileLabel:SetText("Select or create a profile for this\ncharacter:\n\nCurrent Profile: " .. currentProfileName .. ".")
    end

    if self.UpdateProfileActionButtons then
        self:UpdateProfileActionButtons()
    end
end

AuralinVP.profileLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
AuralinVP.profileLabel:SetPoint("TOPLEFT", verticalBar, "TOPRIGHT", 20, 0)
AuralinVP.profileLabel:SetFontObject("GameFontHighlight")
AuralinVP.profileLabel:SetJustifyH("LEFT")
AuralinVP.profileLabel:SetJustifyV("TOP")
AuralinVP:UpdateProfileLabel()

local profileDropDown = nil
local refreshProfileDropDown = nil

local function BuildModernProfileDropDown()
    local hasSetupMenu = type(DropdownButtonMixin) == "table" and type(DropdownButtonMixin.SetupMenu) == "function"
    if not hasSetupMenu then
        return nil, nil
    end

    local ok, dropdown = pcall(CreateFrame, "DropdownButton", "AuralinVP_ProfileDropDown", AuralinVP.MainMenuFrame, "WowStyle1DropdownTemplate")
    if not ok or not dropdown then
        return nil, nil
    end

    dropdown:SetPoint("TOPLEFT", AuralinVP.profileLabel, "BOTTOMLEFT", 0, -10)
    dropdown:SetWidth(190)

    if dropdown.SetDefaultText then
        dropdown:SetDefaultText("Select Profile")
    end

    local function IsSelected(profileName)
        return AuralinVP:GetActiveProfileName() == profileName
    end

    local function SetSelected(profileName)
        AuralinVP:SetActiveProfile(profileName)
        if dropdown.GenerateMenu then
            dropdown:GenerateMenu()
        end
    end

    dropdown:SetupMenu(function(_, rootDescription)
        local profiles = AuralinVP:GetAvailableProfiles()
        if #profiles == 0 then
            local noProfiles = rootDescription:CreateButton("No profiles available")
            if noProfiles and noProfiles.SetEnabled then
                noProfiles:SetEnabled(false)
            end
            return
        end

        for _, profileName in ipairs(profiles) do
            rootDescription:CreateRadio(profileName, IsSelected, SetSelected, profileName)
        end
    end)

    local function Refresh()
        if dropdown.GenerateMenu then
            dropdown:GenerateMenu()
        end
    end

    return dropdown, Refresh
end

local function BuildLegacyProfileDropDown()
    local hasLegacyDropDown = type(UIDropDownMenu_Initialize) == "function"
        and type(UIDropDownMenu_SetWidth) == "function"
        and type(UIDropDownMenu_SetText) == "function"
        and type(UIDropDownMenu_CreateInfo) == "function"
        and type(UIDropDownMenu_AddButton) == "function"

    if not hasLegacyDropDown then
        return nil, nil
    end

    local dropdown = CreateFrame("Frame", "AuralinVP_ProfileDropDown", AuralinVP.MainMenuFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", AuralinVP.profileLabel, "BOTTOMLEFT", -16, -10)
    UIDropDownMenu_SetWidth(dropdown, 160)
    UIDropDownMenu_SetText(dropdown, "Select Profile")

    local function Initialize(_, level)
        if not level then
            return
        end

        local info = UIDropDownMenu_CreateInfo()
        local profiles = AuralinVP:GetAvailableProfiles()
        for _, profileName in ipairs(profiles) do
            info.text = profileName
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, profileName)
                UIDropDownMenu_SetText(dropdown, profileName)
                AuralinVP:SetActiveProfile(profileName)
            end
            UIDropDownMenu_AddButton(info, level)
        end

        local currentProfileName = AuralinVP:GetActiveProfileName() or "Select Profile"
        UIDropDownMenu_SetSelectedName(dropdown, currentProfileName)
        UIDropDownMenu_SetText(dropdown, currentProfileName)
    end

    local function Refresh()
        UIDropDownMenu_Initialize(dropdown, Initialize)
    end

    Refresh()
    return dropdown, Refresh
end

profileDropDown, refreshProfileDropDown = BuildModernProfileDropDown()
if not profileDropDown then
    profileDropDown, refreshProfileDropDown = BuildLegacyProfileDropDown()
end

function AuralinVP:RefreshProfileDropDown()
    if refreshProfileDropDown then
        refreshProfileDropDown()
    end
end

local createProfileEditBox = CreateFrame("EditBox", "AuralinVP_CreateProfileEditBox", AuralinVP.MainMenuFrame, "InputBoxTemplate")
createProfileEditBox:SetSize(130, 20)
if profileDropDown then
    createProfileEditBox:SetPoint("TOPLEFT", profileDropDown, "BOTTOMLEFT", 16, -10)
else
    createProfileEditBox:SetPoint("TOPLEFT", AuralinVP.profileLabel, "BOTTOMLEFT", 0, -20)
end
createProfileEditBox:SetAutoFocus(false)
createProfileEditBox:SetMaxLetters(Constants.MAX_PROFILE_NAME_LENGTH)

local createProfileButton = CreateFrame("Button", "AuralinVP_CreateProfileButton", AuralinVP.MainMenuFrame, "UIPanelButtonTemplate")
createProfileButton:SetSize(80, 22)
createProfileButton:SetPoint("LEFT", createProfileEditBox, "RIGHT", 5, 0)
createProfileButton:SetText("Create")
createProfileButton:SetScript("OnClick", function()
    if AuralinVP.InitializePersistentData then
        AuralinVP:InitializePersistentData()
    end

    local rawName = createProfileEditBox:GetText() or ""
    local newProfileName = type(strtrim) == "function" and strtrim(rawName) or rawName
    if newProfileName == "" then
        AuralinVP:Print("Profile name cannot be empty.")
        return
    end

    local created, createResult = AuralinVP:CreateProfile(newProfileName)
    if not created then
        AuralinVP:Print(createResult or "Unable to create profile.")
        return
    end

    local selected, setResult = AuralinVP:SetActiveProfile(createResult)
    if not selected then
        AuralinVP:Print(setResult or "Profile created but could not be activated.")
    end

    if AuralinVP.RefreshProfileDropDown then
        AuralinVP:RefreshProfileDropDown()
    end
    createProfileEditBox:SetText("")
end)

local deleteProfileButton = CreateFrame("Button", "AuralinVP_DeleteProfileButton", AuralinVP.MainMenuFrame, "UIPanelButtonTemplate")
deleteProfileButton:SetSize(80, 22)
deleteProfileButton:SetPoint("LEFT", createProfileButton, "RIGHT", 5, 0)
deleteProfileButton:SetText("Delete")
deleteProfileButton:SetScript("OnClick", function()
    local activeProfileName = AuralinVP:GetActiveProfileName()
    if not activeProfileName then
        AuralinVP:Print("No active profile is assigned.")
        return
    end

    if AuralinVP:IsDefaultProfile(activeProfileName) then
        AuralinVP:Print("Cannot delete the '" .. Constants.DEFAULT_PROFILE_NAME .. "' profile.")
        return
    end

    StaticPopup_Show("AURALIN_VIEWPORT_DELETE_PROFILE_CONFIRM", activeProfileName, nil, activeProfileName)
end)

function AuralinVP:UpdateProfileActionButtons()
    if not deleteProfileButton then
        return
    end

    local activeProfileName = self:GetActiveProfileName()
    if activeProfileName and not self:IsDefaultProfile(activeProfileName) then
        deleteProfileButton:Enable()
    else
        deleteProfileButton:Disable()
    end
end

createProfileEditBox:SetScript("OnEnterPressed", function(self)
    createProfileButton:Click()
    self:ClearFocus()
end)
createProfileEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
--@end-alpha@

function AuralinVP:RefreshDummyFrameSideAnchors()
    if not self.dummyFrames then
        return
    end

    local top = self.dummyFrames.top:GetHeight()
    local bottom = self.dummyFrames.bottom:GetHeight()

    self.dummyFrames.left:ClearAllPoints()
    self.dummyFrames.left:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -top)
    self.dummyFrames.left:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottom)

    self.dummyFrames.right:ClearAllPoints()
    self.dummyFrames.right:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -top)
    self.dummyFrames.right:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, bottom)
end

function AuralinVP:SyncDummyFramesToSliders()
    if not self.dummyFrames then
        return
    end

    local top = self:ConvertWorldUnitsToPreviewUnits(ClampViewportValue(self.topSlider and self.topSlider:GetValue(), true))
    local bottom = self:ConvertWorldUnitsToPreviewUnits(ClampViewportValue(self.bottomSlider and self.bottomSlider:GetValue(), true))
    local left = self:ConvertWorldUnitsToPreviewUnits(ClampViewportValue(self.leftSlider and self.leftSlider:GetValue(), false))
    local right = self:ConvertWorldUnitsToPreviewUnits(ClampViewportValue(self.rightSlider and self.rightSlider:GetValue(), false))

    self.dummyFrames.top:SetHeight(top)
    self.dummyFrames.bottom:SetHeight(bottom)
    self.dummyFrames.left:SetWidth(left)
    self.dummyFrames.right:SetWidth(right)
    self:RefreshDummyFrameSideAnchors()
end

function AuralinVP:CreateDummyFrames()
    local settings = self:GetCurrentSettings()

    if not self.dummyFrames then
        self.dummyFrames = {
            left = CreateFrame("Frame", nil, UIParent),
            right = CreateFrame("Frame", nil, UIParent),
            top = CreateFrame("Frame", nil, UIParent),
            bottom = CreateFrame("Frame", nil, UIParent),
        }
    end

    local top = settings.top or Constants.DEFAULT_TOP
    local bottom = settings.bottom or Constants.DEFAULT_BOTTOM
    local left = settings.left or Constants.DEFAULT_LEFT
    local right = settings.right or Constants.DEFAULT_RIGHT
    local topPreview = self:ConvertWorldUnitsToPreviewUnits(top)
    local bottomPreview = self:ConvertWorldUnitsToPreviewUnits(bottom)
    local leftPreview = self:ConvertWorldUnitsToPreviewUnits(left)
    local rightPreview = self:ConvertWorldUnitsToPreviewUnits(right)

    self.dummyFrames.top:ClearAllPoints()
    self.dummyFrames.top:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    self.dummyFrames.top:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    self.dummyFrames.top:SetHeight(topPreview)

    self.dummyFrames.bottom:ClearAllPoints()
    self.dummyFrames.bottom:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    self.dummyFrames.bottom:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    self.dummyFrames.bottom:SetHeight(bottomPreview)

    self.dummyFrames.left:SetWidth(leftPreview)
    self.dummyFrames.right:SetWidth(rightPreview)
    self:RefreshDummyFrameSideAnchors()

    for _, frame in pairs(self.dummyFrames) do
        frame:SetParent(UIParent)
        frame:SetFrameStrata("BACKGROUND")
        if not frame.backdrop then
            local backdrop = frame:CreateTexture(nil, "BACKGROUND")
            backdrop:SetAllPoints(frame)
            backdrop:SetColorTexture(1, 0, 0, 0.5)
            frame.backdrop = backdrop
        end
        frame:Hide()
    end

    return self.dummyFrames
end

function AuralinVP:OnMenuOpen()
    local dummyFrames = self:CreateDummyFrames()
    self:SyncDummyFramesToSliders()
    for _, frame in pairs(dummyFrames) do
        frame:Show()
    end
end

AuralinVP.topSlider = CreateViewportSlider(
    "AuralinVP_TopSlider",
    AuralinVP.MainMenuFrame,
    { "LEFT", usageLabel, "BOTTOMLEFT", 0, -35 },
    "Top",
    0,
    Constants.MAX_SLIDER_VALUE,
    1,
    Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val)
        dFrames.top:SetHeight(val)
    end,
    true
)
CreateSliderInput("AuralinVP_TopEditBox", AuralinVP.MainMenuFrame, AuralinVP.topSlider, AuralinVP.topSlider)

AuralinVP.leftSlider = CreateViewportSlider(
    "AuralinVP_LeftSlider",
    AuralinVP.MainMenuFrame,
    { "LEFT", AuralinVP.topSlider, "BOTTOMLEFT", 0, -50 },
    "Left",
    0,
    Constants.MAX_SLIDER_VALUE,
    1,
    Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val)
        dFrames.left:SetWidth(val)
    end,
    false
)
CreateSliderInput("AuralinVP_LeftEditBox", AuralinVP.MainMenuFrame, AuralinVP.leftSlider, AuralinVP.leftSlider)

AuralinVP.rightSlider = CreateViewportSlider(
    "AuralinVP_RightSlider",
    AuralinVP.MainMenuFrame,
    { "LEFT", AuralinVP.leftSlider, "BOTTOMLEFT", 0, -50 },
    "Right",
    0,
    Constants.MAX_SLIDER_VALUE,
    1,
    Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val)
        dFrames.right:SetWidth(val)
    end,
    false
)
CreateSliderInput("AuralinVP_RightEditBox", AuralinVP.MainMenuFrame, AuralinVP.rightSlider, AuralinVP.rightSlider)

AuralinVP.bottomSlider = CreateViewportSlider(
    "AuralinVP_BottomSlider",
    AuralinVP.MainMenuFrame,
    { "LEFT", AuralinVP.rightSlider, "BOTTOMLEFT", 0, -50 },
    "Bottom",
    0,
    Constants.MAX_SLIDER_VALUE,
    1,
    Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val)
        dFrames.bottom:SetHeight(val)
    end,
    true
)
CreateSliderInput("AuralinVP_BottomEditBox", AuralinVP.MainMenuFrame, AuralinVP.bottomSlider, AuralinVP.bottomSlider)

local saveButton = CreateFrame("Button", "AuralinVP_SaveButton", AuralinVP.MainMenuFrame, "UIPanelButtonTemplate")
saveButton:SetSize(100, 22)
saveButton:SetPoint("BOTTOM", AuralinVP.MainMenuFrame, "BOTTOM", 0, 10)
saveButton:SetText("Save & Reload")
saveButton:SetScript("OnClick", function()
    AuralinVP:SaveAndReload()
end)

AuralinVP.MainMenuFrame:SetScript("OnShow", function()
    if AuralinVP.UpdateSlidersWithCurrentSettings then
        AuralinVP:UpdateSlidersWithCurrentSettings()
    end

    --@alpha@
    if AuralinVP.RefreshProfileDropDown then
        AuralinVP:RefreshProfileDropDown()
    end
    --@end-alpha@

    AuralinVP:OnMenuOpen()
end)

local MenuConfig = {
    topSlider = AuralinVP.topSlider,
    leftSlider = AuralinVP.leftSlider,
    rightSlider = AuralinVP.rightSlider,
    bottomSlider = AuralinVP.bottomSlider,
}

return MenuConfig
