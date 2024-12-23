local addonName, AuralinVP = ...
local Constants = AuralinVP.Constants

local function CreateSlider(sliderName, parent, anchorPoint, labelText, minVal, maxVal, step, length)
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint(unpack(anchorPoint))
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

local function CreateViewportSlider(
    sliderName, parent, anchorPoint, labelText, minVal, maxVal, step, length,
    dimensionSetter, isVertical)
    local slider = CreateSlider(sliderName, parent, anchorPoint, labelText, minVal, maxVal, step, length)
    slider:SetScript("OnValueChanged", function(self, rawValue)
        local screenWidth, screenHeight = GetPhysicalScreenSize()
        local clampDim = isVertical and screenHeight or screenWidth
        local clampedValue = max(0, min(rawValue, clampDim / 2))
        local finalValue = math.floor(clampedValue + Constants.ROUNDING_THRESHOLD)
        self.value:SetText(finalValue)
        if not AuralinVP.dummyFrames then
            AuralinVP:CreateDummyFrames()
        end
        if AuralinVP.dummyFrames then
            dimensionSetter(AuralinVP.dummyFrames, finalValue)
        end
    end)
    return slider
end

local function CreateSliderInput(editBoxName, parent, anchorTo, sliderTable)
    local editBox = CreateFrame("EditBox", editBoxName, parent, "InputBoxTemplate")
    editBox:SetSize(50, 20)
    editBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(5)
    editBox:SetNumeric(true)
    editBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            sliderTable:SetValue(value)
        end
        self:ClearFocus()
    end)
    return editBox
end

-- Add background texture (if necessary)
local texture = AuralinVP.MainMenuFrame:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints(AuralinVP.MainMenuFrame)
texture:SetColorTexture(0, 0, 0, 1) -- Example black background

-- Create a texture for the frame
texture:SetAllPoints(AuralinVP.MainMenuFrame)

-- Create a frame to handle events
local button = CreateFrame("Button", "SaveButtonName", AuralinVP.MainMenuFrame,
    "UIPanelButtonTemplate")
button:SetPoint("BOTTOM", AuralinVP.MainMenuFrame, "BOTTOM", 0, 10)

--Create Usage instructions
local usageLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
usageLabel:SetPoint("TOP", AuralinVP.MainMenuFrame, "TOP", 0, -35)
usageLabel:SetFontObject("GameFontHighlight")
usageLabel:SetJustifyH("LEFT")
usageLabel:SetJustifyV("TOP")
usageLabel:SetText("This add-on adjusts the size of the frame\nused by the game client to render the\ngame-world. For changes to take place\nyou must 'Save & Reload'.")

-- Function to create dummy frames
function AuralinVP:CreateDummyFrames()
    if self.dummyFrames then return end -- prevent self duplication
    local screenWidth, screenHeight

    local settings = AuralinVP:GetCurrentSettings()

    self.dummyFrames = {
        left = CreateFrame("Frame", "leftDummyFrame", nil),
        right = CreateFrame("Frame", "rightDummyFrame", nil),
        top = CreateFrame("Frame", "topDummyFrame", nil),
        bottom = CreateFrame("Frame", "bottomDummyFrame", nil),
    }
    -- Set positions and sizes based on current settings
    self.dummyFrames.left:ClearAllPoints()
    self.dummyFrames.left:SetPoint("TOPLEFT", nil, "TOPLEFT", 0, -(settings.top or 0))
    self.dummyFrames.left:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 0, (settings.bottom or 0))
    self.dummyFrames.left:SetWidth(settings.left or Constants.DEFAULT_LEFT)

    self.dummyFrames.right:ClearAllPoints()
    self.dummyFrames.right:SetPoint("TOPRIGHT", nil, "TOPRIGHT", 0, -(settings.top or 0))
    self.dummyFrames.right:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, (settings.bottom or 0))
    self.dummyFrames.right:SetWidth(settings.right or Constants.DEFAULT_RIGHT)

    self.dummyFrames.top:ClearAllPoints()
    self.dummyFrames.top:SetPoint("TOPLEFT", nil, "TOPLEFT", 0, 0)
    self.dummyFrames.top:SetPoint("TOPRIGHT", nil, "TOPRIGHT", 0, 0)
    self.dummyFrames.top:SetHeight(settings.top or Constants.DEFAULT_TOP)

    self.dummyFrames.bottom:ClearAllPoints()
    self.dummyFrames.bottom:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 0, 0)
    self.dummyFrames.bottom:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, 0)
    self.dummyFrames.bottom:SetHeight(settings.bottom or Constants.DEFAULT_BOTTOM)

    -- Hide the frames initially
    for _, frame in pairs(self.dummyFrames) do
        frame:Hide()
        end
    end

-- Function to create dummy frames upon menu open
function AuralinVP:OnMenuOpen()
    self:CreateDummyFrames()
    for _, frame in pairs(self.dummyFrames) do
        -- Add a backdrop using a texture
        local backdrop = frame:CreateTexture(nil, "BACKGROUND")
        backdrop:SetAllPoints(frame)
        backdrop:SetColorTexture(1, 0, 0, 0.5) -- Semi-transparent red
        frame.backdrop = backdrop -- Store the backdrop for later use

        frame:SetFrameStrata("BACKGROUND")
        frame:Show()
    end
end

-- Create a slider for top
AuralinVP.topSlider = CreateViewportSlider("TopSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", usageLabel, "BOTTOMLEFT", 0, -35}, "Top", 0, Constants.MAX_SLIDER_VALUE, 1, Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val) dFrames.top:SetHeight(val) end, true)
-- Create a text input box for top
local topEditBox = CreateSliderInput("TopEditBoxName", AuralinVP.MainMenuFrame, AuralinVP.topSlider, AuralinVP.topSlider)

-- Create a slider for left
AuralinVP.leftSlider = CreateViewportSlider("LeftSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", AuralinVP.topSlider, "BOTTOMLEFT", 0, -50}, "Left", 0, Constants.MAX_SLIDER_VALUE, 1, Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val) dFrames.left:SetWidth(val) end, false)
-- Create a text input box for left
local leftEditBox = CreateSliderInput("LeftEditBoxName", AuralinVP.MainMenuFrame, AuralinVP.leftSlider, AuralinVP.leftSlider)

-- Create a slider for right
AuralinVP.rightSlider = CreateViewportSlider("RightSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", AuralinVP.leftSlider, "BOTTOMLEFT", 0, -50}, "Right", 0, Constants.MAX_SLIDER_VALUE, 1, Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val) dFrames.right:SetWidth(val) end, false)
texture:SetColorTexture(0,0,0,1)
-- Create a text input box for right
local rightEditBox = CreateSliderInput("RightEditBoxName", AuralinVP.MainMenuFrame, AuralinVP.rightSlider, AuralinVP.rightSlider)

-- Create a slider for bottom
AuralinVP.bottomSlider = CreateViewportSlider("BottomSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", AuralinVP.rightSlider, "BOTTOMLEFT", 0, -50}, "Bottom", 0, Constants.MAX_SLIDER_VALUE, 1, Constants.DEFAULT_SLIDER_LENGTH,
    function(dFrames, val) dFrames.bottom:SetHeight(val) end, true)
-- Create a text input box for bottom
local bottomEditBox = CreateSliderInput("BottomEditBoxName", AuralinVP.MainMenuFrame, AuralinVP.bottomSlider, AuralinVP.bottomSlider)

-- Create a button for saving and reloading UI
button:SetSize(100, 22)
button:SetText("Save & Reload")
button:SetScript("OnClick", function()
    if AuralinVP.dummyFrames then -- take values from the dummy frames
        Auralin_Viewport_Settings = {
            top     = math.floor(AuralinVP.dummyFrames.top:GetHeight()      + Constants.ROUNDING_THRESHOLD),
            left    = math.floor(AuralinVP.dummyFrames.left:GetWidth()      + Constants.ROUNDING_THRESHOLD),
            right   = math.floor(AuralinVP.dummyFrames.right:GetWidth()     + Constants.ROUNDING_THRESHOLD),
            bottom  = math.floor(AuralinVP.dummyFrames.bottom:GetHeight()   + Constants.ROUNDING_THRESHOLD),
        }
    else -- if dummy frames don't exists, fall back to existing settings or defaults
        print("Error: Dummy frames not initialized.")
    end
    ReloadUI()
end)

AuralinVP.MainMenuFrame:SetScript("OnShow", function()
    AuralinVP:OnMenuOpen()
end)

local MenuConfig = {
    topSlider       = AuralinVP.topSlider,
    leftSlider      = AuralinVP.leftSlider,
    rightSlider     = AuralinVP.rightSlider,
    bottomSlider    = AuralinVP.bottomSlider
}
return MenuConfig
