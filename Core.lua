local addonName, AuralinVP = ...

-- Define global variables
AuralinVP = AuralinVP or {}

function AuralinVP:DestroyDummyFrames()
    if not self.dummyFrames then return end

    for _, frame in pairs(self.dummyFrames) do
        frame:Hide()
        frame:SetParent(nil)
    end
    self.dummyFrames = nil
end

function AuralinVP:ChangesDetected()
    if not self.dummyFrames then return false end

    local current = {
        top     = self.dummyFrames.top:GetHeight(),
        left    = self.dummyFrames.left:GetWidth(),
        right   = self.dummyFrames.right:GetWidth(),
        bottom  = self.dummyFrames.bottom:GetHeight(),
    }

    local saved = Auralin_Viewport_Settings or { top = 0, left = 0, right = 0, bottom = 112 }

    return current.top ~= saved.top or current.left ~= saved.left or
        current.right ~= saved.right or current.bottom ~= saved.bottom
end

-- Function to hide dummy frames upon menu close
function AuralinVP:OnMenuClose()
    print("Menu closed.")
    if self:ChangesDetected() then
        print("Changes detected.")
        StaticPopupDialogs["AURALIN_UNSAVED_CHANGES"] = {
            text        = "You have unsaved changes. \nSave & Reload or Cancel to discard changes.",
            button1     = "Save & Reload",
            button2     = "Cancel",
            OnAccept    = function()
                Auralin_Viewport_Settings = {
                    top     = math.floor(self.dummyFrames.top:GetHeight()       + 0.5),
                    left    = math.floor(self.dummyFrames.left:GetWidth()       + 0.5),
                    right   = math.floor(self.dummyFrames.right:GetWidth()      + 0.5),
                    bottom  = math.floor(self.dummyFrames.bottom:GetHeight()    + 0.5),
                }
                ReloadUI()
            end,
            OnCancel = function()
                -- Restore dummy frames and WorldFrame to saved settings
                if Auralin_Viewport_Settings then
                    local top       = Auralin_Viewport_Settings.top or 0
                    local bottom    = Auralin_Viewport_Settings.bottom or 112
                    local left      = Auralin_Viewport_Settings.left or 0
                    local right     = Auralin_Viewport_Settings.right or 0
            
                    -- Reset dummy frames
                    if AuralinVP.dummyFrames then
                        AuralinVP.dummyFrames.top:ClearAllPoints()
                        AuralinVP.dummyFrames.top:SetPoint("TOPLEFT", nil, "TOPLEFT", 0, 0)
                        AuralinVP.dummyFrames.top:SetPoint("TOPRIGHT", nil, "TOPRIGHT", 0, 0)
                        AuralinVP.dummyFrames.top:SetHeight(top)
            
                        AuralinVP.dummyFrames.bottom:ClearAllPoints()
                        AuralinVP.dummyFrames.bottom:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 0, 0)
                        AuralinVP.dummyFrames.bottom:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, 0)
                        AuralinVP.dummyFrames.bottom:SetHeight(bottom)
            
                        AuralinVP.dummyFrames.left:ClearAllPoints()
                        AuralinVP.dummyFrames.left:SetPoint("TOPLEFT", nil, "TOPLEFT", 0, -top)
                        AuralinVP.dummyFrames.left:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 0, bottom)
                        AuralinVP.dummyFrames.left:SetWidth(left)
            
                        AuralinVP.dummyFrames.right:ClearAllPoints()
                        AuralinVP.dummyFrames.right:SetPoint("TOPRIGHT", nil, "TOPRIGHT", 0, -top)
                        AuralinVP.dummyFrames.right:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, bottom)
                        AuralinVP.dummyFrames.right:SetWidth(right)
                    end
            
                    -- Restore WorldFrame
                    WorldFrame:ClearAllPoints()
                    WorldFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", left, -top)
                    WorldFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", -right, bottom)
                end
            
                -- Destroy dummy frames and hide menu
                AuralinVP:DestroyDummyFrames()
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
        print("No changes detected.")
        -- No changes detected; clean up
        AuralinVP:DestroyDummyFrames()
    end
end

AuralinVP.MainMenuFrame = CreateFrame("Frame", "MainMenuFrame", UIParent, "BasicFrameTemplateWithInset")
AuralinVP.MainMenuFrame:SetScript("OnHide", function() AuralinVP:OnMenuClose() end)
AuralinVP.MainMenuFrame:SetSize(300, 400)
AuralinVP.MainMenuFrame:SetPoint("CENTER")
AuralinVP.MainMenuFrame:Hide()

-- Add title
AuralinVP.MainMenuFrame.title = AuralinVP.MainMenuFrame:CreateFontString(nil, "OVERLAY")
AuralinVP.MainMenuFrame.title:SetFontObject("GameFontHighlight")
AuralinVP.MainMenuFrame.title:SetPoint("LEFT", AuralinVP.MainMenuFrame.TitleBg, "LEFT", 5, 0)
AuralinVP.MainMenuFrame.title:SetText("Auralin Viewport")

function AuralinVP:InitializeMenu()
    local frame = self.MainMenuFrame

    -- Create sliders, buttons, and labels here
    self.topSlider = CreateFrame("Slider", "TopSliderName", frame, "OptionsSliderTemplate")
    self.topSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -50)
    self.topSlider:SetMinMaxValues(0, 500)
    self.topSlider:SetValueStep(1)

    -- Add Save & Reload button
    local button = CreateFrame("Button", "SaveButtonName", frame, "UIPanelButtonTemplate")
    button:SetSize(100, 22)
    button:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    button:SetText("Save & Reload")
    button:SetScript("OnClick", function()
        if self.dummyFrames then
            Auralin_Viewport_Settings = {
                top     = self.dummyFrames.top:GetHeight(),
                left    = self.dummyFrames.left:GetWidth(),
                right   = self.dummyFrames.right:GetWidth(),
                bottom  = self.dummyFrames.bottom:GetHeight(),
            }
            ReloadUI()
        else
            print("Error: Dummy frames not initialized.")
        end
    end)
end

AuralinVP:InitializeMenu()

AuralinVP.topSlider, AuralinVP.leftSlider, AuralinVP.rightSlider, AuralinVP.bottomSlider = nil, nil, nil, nil
AuralinVP.dummyFrames = nil -- Store references to dummy frames

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
    self.dummyFrames.left:SetWidth(settings.left or 0)

    self.dummyFrames.right:ClearAllPoints()
    self.dummyFrames.right:SetPoint("TOPRIGHT", nil, "TOPRIGHT", 0, -(settings.top or 0))
    self.dummyFrames.right:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, (settings.bottom or 0))
    self.dummyFrames.right:SetWidth(settings.right or 0)

    self.dummyFrames.top:ClearAllPoints()
    self.dummyFrames.top:SetPoint("TOPLEFT", nil, "TOPLEFT", 0, 0)
    self.dummyFrames.top:SetPoint("TOPRIGHT", nil, "TOPRIGHT", 0, 0)
    self.dummyFrames.top:SetHeight(settings.top or 0)

    self.dummyFrames.bottom:ClearAllPoints()
    self.dummyFrames.bottom:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT", 0, 0)
    self.dummyFrames.bottom:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, 0)
    self.dummyFrames.bottom:SetHeight(settings.bottom or 112)

    -- Hide the frames initially
    for _, frame in pairs(self.dummyFrames) do
        frame:Hide()
        end
    end

-- Function to retrieve current settings
function AuralinVP:GetCurrentSettings()
    return {
        top     = self.topSlider and self.topSlider:GetValue() or 0,
        left    = self.leftSlider and self.leftSlider:GetValue() or 0,
        right   = self.rightSlider and self.rightSlider:GetValue() or 0,
        bottom  = self.bottomSlider and self.bottomSlider:GetValue() or 112,
    }
end

-- Function to create dummy frames upon menu open
function AuralinVP:OnMenuOpen()
    self:CreateDummyFrames()
    for _, frame in pairs(self.dummyFrames) do
        -- Add a backdrop using a texture
        local backdrop = frame:CreateTexture(nil, "BACKGROUND")
        backdrop:SetAllPoints(frame)
        backdrop:SetColorTexture(0, 0, 0, 0.5) -- Semi-transparent black
        frame.backdrop = backdrop -- Store the backdrop for later use

        frame:SetFrameStrata("BACKGROUND")
        frame:Show()
    end
end
