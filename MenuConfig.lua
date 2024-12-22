local addonName, AuralinVP = ...
local Constants = AuralinVP.Constants

local function CreateSlider(sliderName, parent, anchorPoint, labelText, minVal, maxVal, step)
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint(unpack(anchorPoint))
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

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
usageLabel:SetText("|cffdc143cWarning:|r This add-on adjusts the size of the\nframe the used by the game client to render\nthe game-world. To avoid the client from\ncrashing you are recommended to\n'Save & Reload' after every change.")

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
AuralinVP.topSlider = CreateSlider("TopSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", usageLabel, "BOTTOMLEFT", 0, -35}, "Top", 0, Constants.MAX_SLIDER_VALUE, 1)
AuralinVP.topSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = max(0, min(value, screenHeight / 2))
    value = math.floor(value + Constants.ROUNDING_THRESHOLD) -- Round value to nearest integer
    self.value:SetText(value)
    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end
    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.top then
        AuralinVP.dummyFrames.top:SetHeight(value)
    end
end)
-- Create a label for the top slider
local topLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
topLabel:SetPoint("LEFT", AuralinVP.topSlider, "LEFT", 0, 15)
topLabel:SetFontObject("GameFontHighlight")
topLabel:SetText("Top")
-- Create a FontString for the top slider's value
AuralinVP.topSlider.value = AuralinVP.topSlider:CreateFontString(nil, "OVERLAY")
AuralinVP.topSlider.value:SetPoint("BOTTOM", AuralinVP.topSlider, "TOP", 0, 0)
AuralinVP.topSlider.value:SetFontObject("GameFontHighlight")
-- Create a text input box for top
local topEditBox = CreateFrame("EditBox", "TopEditBoxName", AuralinVP.MainMenuFrame, "InputBoxTemplate")
topEditBox:SetSize(50, 20)
topEditBox:SetPoint("LEFT", AuralinVP.topSlider, "RIGHT", 10, 0)
topEditBox:SetAutoFocus(false)
topEditBox:SetMaxLetters(5)
topEditBox:SetNumeric(true)
topEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        AuralinVP.topSlider:SetValue(value)
    end
    self:ClearFocus()
end)

-- Create a slider for left
AuralinVP.leftSlider = CreateSlider("LeftSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", usageLabel, "BOTTOMLEFT", 0, -80}, "Left", 0, Constants.MAX_SLIDER_VALUE, 1)
AuralinVP.leftSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = max(0, min(value, screenWidth / 2))
    value = math.floor(value + Constants.ROUNDING_THRESHOLD) -- Round value to nearest integer
    self.value:SetText(value)
    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end
    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.left then
        AuralinVP.dummyFrames.left:SetWidth(value)
    end
end)
-- Create a label for the left slider
local leftLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
leftLabel:SetPoint("LEFT", AuralinVP.leftSlider, "LEFT", 0, 15)
leftLabel:SetFontObject("GameFontHighlight")
leftLabel:SetText("Left")
-- Create a FontString for the left slider's value
AuralinVP.leftSlider.value = AuralinVP.leftSlider:CreateFontString(nil, "OVERLAY")
AuralinVP.leftSlider.value:SetPoint("BOTTOM", AuralinVP.leftSlider, "TOP", 0, 0)
AuralinVP.leftSlider.value:SetFontObject("GameFontHighlight")
-- Create a text input box for left
local leftEditBox = CreateFrame("EditBox", "LeftEditBoxName", AuralinVP.MainMenuFrame, "InputBoxTemplate")
leftEditBox:SetSize(50, 20)
leftEditBox:SetPoint("LEFT", AuralinVP.leftSlider, "RIGHT", 10, 0)
leftEditBox:SetAutoFocus(false)
leftEditBox:SetMaxLetters(5)
leftEditBox:SetNumeric(true)
leftEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        AuralinVP.leftSlider:SetValue(value)
    end
    self:ClearFocus()
end)

-- Create a slider for right
AuralinVP.rightSlider = CreateSlider("RightSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", AuralinVP.leftSlider, "BOTTOMLEFT", 0, -50}, "Right", 0, Constants.MAX_SLIDER_VALUE, 1)
AuralinVP.rightSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = max(0, min(value, screenWidth / 2)) -- Ensure value is within valid range
    value = math.floor(value + Constants.ROUNDING_THRESHOLD) -- Round value to nearest integer
    self.value:SetText(value)
    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end
    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.right then
        AuralinVP.dummyFrames.right:SetWidth(value)
    end
end)
-- Create a label for the right slider
local rightLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
rightLabel:SetPoint("LEFT", AuralinVP.rightSlider, "LEFT", 0, 15)
rightLabel:SetFontObject("GameFontHighlight")
rightLabel:SetText("Right")
-- Create a FontString for the right slider's value
AuralinVP.rightSlider.value = AuralinVP.rightSlider:CreateFontString(nil, "OVERLAY")
AuralinVP.rightSlider.value:SetPoint("BOTTOM", AuralinVP.rightSlider, "TOP", 0, 0)
AuralinVP.rightSlider.value:SetFontObject("GameFontHighlight")
texture:SetColorTexture(0,0,0,1)
-- Create a text input box for right
local rightEditBox = CreateFrame("EditBox", "RightEditBoxName", AuralinVP.MainMenuFrame, "InputBoxTemplate")
rightEditBox:SetSize(50, 20)
rightEditBox:SetPoint("LEFT", AuralinVP.rightSlider, "RIGHT", 10, 0)
rightEditBox:SetAutoFocus(false)
rightEditBox:SetMaxLetters(5)
rightEditBox:SetNumeric(true)
rightEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        AuralinVP.rightSlider:SetValue(value)
    end
    self:ClearFocus()
end)

-- Create a slider for bottom
AuralinVP.bottomSlider = CreateSlider("BottomSliderName", AuralinVP.MainMenuFrame, 
    {"LEFT", AuralinVP.rightSlider, "BOTTOMLEFT", 0, -50}, "Bottom", 0, Constants.MAX_SLIDER_VALUE, 1)
AuralinVP.bottomSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = max(0, min(value, screenHeight / 2)) -- Ensure value is within valid range
    value = math.floor(value + Constants.ROUNDING_THRESHOLD) -- Round value to nearest integer
    self.value:SetText(value)
    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end
    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.bottom then
        AuralinVP.dummyFrames.bottom:SetHeight(value)
    end
end)
-- Create a label for the bottom slider
local bottomLabel = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
bottomLabel:SetPoint("LEFT", AuralinVP.bottomSlider, "LEFT", 0, 15)
bottomLabel:SetFontObject("GameFontHighlight")
bottomLabel:SetText("Bottom")
-- Create a FontString for the bottom slider's value
AuralinVP.bottomSlider.value = AuralinVP.bottomSlider:CreateFontString(nil, "OVERLAY")
AuralinVP.bottomSlider.value:SetPoint("BOTTOM", AuralinVP.bottomSlider, "TOP", 0, 0)
AuralinVP.bottomSlider.value:SetFontObject("GameFontHighlight")
-- Create a text input box for bottom
local bottomEditBox = CreateFrame("EditBox", "BottomEditBoxName", AuralinVP.MainMenuFrame, "InputBoxTemplate")
bottomEditBox:SetSize(50, 20)
bottomEditBox:SetPoint("LEFT", AuralinVP.bottomSlider, "RIGHT", 10, 0)
bottomEditBox:SetAutoFocus(false)
bottomEditBox:SetMaxLetters(5)
bottomEditBox:SetNumeric(true)
bottomEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        AuralinVP.bottomSlider:SetValue(value)
    end
    self:ClearFocus()
end)
-- Create a button for saving and reloading UI
button:SetSize(100, 22)
button:SetText("Save & Reload")
button:SetScript("OnClick", function()
    if AuralinVP.dummyFrames then -- take values from the dummy frames
        Auralin_Viewport_Settings = {
            top     = math.floor(AuralinVP.dummyFrames.top:GetHeight()      + 0.5),
            left    = math.floor(AuralinVP.dummyFrames.left:GetWidth()      + 0.5),
            right   = math.floor(AuralinVP.dummyFrames.right:GetWidth()     + 0.5),
            bottom  = math.floor(AuralinVP.dummyFrames.bottom:GetHeight()   + 0.5),
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
