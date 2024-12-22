local addonName, AuralinVP = ...

function UpdateSlidersWithCurrentSettings()
    if Auralin_Viewport_Settings == nil then
        Auralin_Viewport_Settings = { bottom = 112, top = 0, left = 0, right = 0 }
    end
    -- Set the slider values to those in ViewPort
    AuralinVP.topSlider:SetValue(Auralin_Viewport_Settings.top)
    AuralinVP.leftSlider:SetValue(Auralin_Viewport_Settings.left)
    AuralinVP.rightSlider:SetValue(Auralin_Viewport_Settings.right)
    AuralinVP.bottomSlider:SetValue(Auralin_Viewport_Settings.bottom)

    -- Update the displayed values
    AuralinVP.topSlider.value:SetText(Auralin_Viewport_Settings.top)
    AuralinVP.leftSlider.value:SetText(Auralin_Viewport_Settings.left)
    AuralinVP.rightSlider.value:SetText(Auralin_Viewport_Settings.right)
    AuralinVP.bottomSlider.value:SetText(Auralin_Viewport_Settings.bottom)
end

-- Update the displayed top value when the slider value changes
AuralinVP.topSlider:SetScript("OnValueChanged", function(self, value)
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    value = max(0, min(value, screenHeight / 2))
    value = math.floor(value + 0.5)
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
    value = max(0, min(value, screenWidth / 2))
    value = math.floor(value + 0.5) -- Round value to nearest integer
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
    value = max(0, min(value, screenWidth / 2)) -- Ensure value is within valid range
    value = math.floor(value + 0.5) -- Round value to nearest integer
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
    value = max(0, min(value, screenHeight / 2)) -- Ensure value is within valid range
    value = math.floor(value + 0.5) -- Round value to nearest integer
    self.value:SetText(value)

    if not AuralinVP.dummyFrames then
        AuralinVP:CreateDummyFrames()
    end

    if AuralinVP.dummyFrames and AuralinVP.dummyFrames.bottom then
        AuralinVP.dummyFrames.bottom:SetHeight(value)
    end
end)
