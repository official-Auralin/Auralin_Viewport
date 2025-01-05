local addonName, AuralinVP = ...
local Constants = AuralinVP.Constants

-- Function to retrieve current settings
function AuralinVP:GetCurrentSettings()
    --[===[@non-alpha@
    return {
        top     = (Auralin_Viewport_Settings and Auralin_Viewport_Settings.top ~= nil and Auralin_Viewport_Settings.top)  or
                (self.topSlider and self.topSlider:GetValue() or Constants.DEFAULT_TOP),
        left    = (Auralin_Viewport_Settings and Auralin_Viewport_Settings.left ~=nil and Auralin_Viewport_Settings.left) or
                (self.leftSlider and self.leftSlider:GetValue() or Constants.DEFAULT_LEFT),
        right   = (Auralin_Viewport_Settings and Auralin_Viewport_Settings.right ~= nil and Auralin_Viewport_Settings.right) or
                (self.rightSlider and self.rightSlider:GetValue() or Constants.DEFAULT_RIGHT),
        bottom  = (Auralin_Viewport_Settings and Auralin_Viewport_Settings.bottom ~= nil and Auralin_Viewport_Settings.bottom)  or
                (self.bottomSlider and self.bottomSlider:GetValue() or Constants.DEFAULT_BOTTOM),
    }
    --@end-non-alpha@]===]
    --@alpha@
    local profile = self:GetActiveProfile()
    return {
        top     = profile.top or (self.topSlider and self.topSlider:GetValue()) or Constants.DEFAULT_TOP,
        left    = profile.left or (self.leftSlider and self.leftSlider:GetValue()) or Constants.DEFAULT_LEFT,
        right   = profile.right or (self.rightSlider and self.rightSlider:GetValue()) or Constants.DEFAULT_RIGHT,
        bottom  = profile.bottom or (self.bottomSlider and self.bottomSlider:GetValue()) or Constants.DEFAULT_BOTTOM,
    }
    --@end-alpha@
end

function UpdateSlidersWithCurrentSettings()
    --@alpha@
    local profile = AuralinVP:GetActiveProfile()
    if not profile.top then profile.top         = Constants.DEFAULT_TOP end
    if not profile.left then profile.left       = Constants.DEFAULT_LEFT end
    if not profile.right then profile.right     = Constants.DEFAULT_RIGHT end
    if not profile.bottom then profile.bottom   = Constants.DEFAULT_BOTTOM end
    --@end-alpha@
    if Auralin_Viewport_Settings == nil then
        Auralin_Viewport_Settings = {
            top     = Constants.DEFAULT_TOP,
            left    = Constants.DEFAULT_LEFT,
            right   = Constants.DEFAULT_RIGHT,
            bottom  = Constants.DEFAULT_BOTTOM,
        }
    end
    --[===[@non-alpha@
    -- Set the slider values to those in ViewPort
    AuralinVP.topSlider:SetValue(Auralin_Viewport_Settings.top)
    AuralinVP.leftSlider:SetValue(Auralin_Viewport_Settings.left)
    AuralinVP.rightSlider:SetValue(Auralin_Viewport_Settings.right)
    AuralinVP.bottomSlider:SetValue(Auralin_Viewport_Settings.bottom)
    --@end-non-alpha@]===]
    --@alpha@
    -- Set the slider values
    AuralinVP.topSlider:SetValue(profile.top)
    AuralinVP.leftSlider:SetValue(profile.left)
    AuralinVP.rightSlider:SetValue(profile.right)
    AuralinVP.bottomSlider:SetValue(profile.bottom)
    --@end-alpha@

    --[===[@non-alpha@
    -- Update the displayed values
    AuralinVP.topSlider.value:SetText(Auralin_Viewport_Settings.top)
    AuralinVP.leftSlider.value:SetText(Auralin_Viewport_Settings.left)
    AuralinVP.rightSlider.value:SetText(Auralin_Viewport_Settings.right)
    AuralinVP.bottomSlider.value:SetText(Auralin_Viewport_Settings.bottom)
    --@end-non-alpha@]===]
    --@alpha@
    -- Update the displayed text
    AuralinVP.topSlider.value:SetText(profile.top)
    AuralinVP.leftSlider.value:SetText(profile.left)
    AuralinVP.rightSlider.value:SetText(profile.right)
    AuralinVP.bottomSlider.value:SetText(profile.bottom)
end

local function ValidateSliderValue(value, maxValue)
    value = max(0, min(value, maxValue))
    return math.floor(value + Constants.ROUNDING_THRESHOLD)
end


-- Update the displayed top value when the slider value changes
AuralinVP.topSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = ValidateSliderValue(value, screenHeight / 2)
    self.value:SetText(value)

    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end
    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.top then
        AuralinVP.dummyFrames.top:SetHeight(value)
    end
end)

-- Update the displayed left value when the slider value changes
AuralinVP.leftSlider:SetScript("OnValueChanged", function(self, value)  
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = ValidateSliderValue(value, screenWidth / 2)
    self.value:SetText(value)

    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end

    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.left then
        AuralinVP.dummyFrames.left:SetWidth(value)
    end
end)

-- Update the displayed right value when the slider value changes
AuralinVP.rightSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = ValidateSliderValue(value, screenWidth / 2)
    self.value:SetText(value)

    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end 

    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.right then
        AuralinVP.dummyFrames.right:SetWidth(value)
    end
end)

-- Update the displayed bottom value when the slider value changes
AuralinVP.bottomSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = ValidateSliderValue(value, screenHeight / 2)
    self.value:SetText(value)

    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end

    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.bottom then
        AuralinVP.dummyFrames.bottom:SetHeight(value)
    end
end)
