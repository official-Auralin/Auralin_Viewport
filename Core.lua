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
        top = self.dummyFrames.top:GetHeight(),
        left = self.dummyFrames.left:GetWidth(),
        right = self.dummyFrames.right:GetWidth(),
        bottom = self.dummyFrames.bottom:GetHeight(),
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
            text = "You have unsaved changes. \nSave & Reload or Cancel to discard changes.",
            button1 = "Save & Reload",
            button2 = "Cancel",
            OnAccept = function()
                Auralin_Viewport_Settings = {
                    top = self.dummyFrames.top:GetHeight(),
                    left = self.dummyFrames.left:GetWidth(),
                    right = self.dummyFrames.right:GetWidth(),
                    bottom = self.dummyFrames.bottom:GetHeight(),
                }
                ReloadUI()
            end,
            OnCancel = function()
                -- Restore dummy frames and WorldFrame to saved settings
                if Auralin_Viewport_Settings then
                    local top = Auralin_Viewport_Settings.top or 0
                    local bottom = Auralin_Viewport_Settings.bottom or 112
                    local left = Auralin_Viewport_Settings.left or 0
                    local right = Auralin_Viewport_Settings.right or 0
            
                    -- Reset dummy frames
                    if AuralinVP.dummyFrames then
                        AuralinVP.dummyFrames.top:ClearAllPoints()
                        AuralinVP.dummyFrames.top:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
                        AuralinVP.dummyFrames.top:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
                        AuralinVP.dummyFrames.top:SetHeight(top)
            
                        AuralinVP.dummyFrames.bottom:ClearAllPoints()
                        AuralinVP.dummyFrames.bottom:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
                        AuralinVP.dummyFrames.bottom:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
                        AuralinVP.dummyFrames.bottom:SetHeight(bottom)
            
                        AuralinVP.dummyFrames.left:ClearAllPoints()
                        AuralinVP.dummyFrames.left:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -top)
                        AuralinVP.dummyFrames.left:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottom)
                        AuralinVP.dummyFrames.left:SetWidth(left)
            
                        AuralinVP.dummyFrames.right:ClearAllPoints()
                        AuralinVP.dummyFrames.right:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, -top)
                        AuralinVP.dummyFrames.right:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, bottom)
                        AuralinVP.dummyFrames.right:SetWidth(right)
                    end
            
                    -- Restore WorldFrame
                    WorldFrame:ClearAllPoints()
                    WorldFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, -top)
                    WorldFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -right, bottom)
                end
            
                -- Destroy dummy frames and hide menu
                AuralinVP:DestroyDummyFrames()
                if AuralinVP.MainMenuFrame then
                    AuralinVP.MainMenuFrame:Hide()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
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
                top = self.dummyFrames.top:GetHeight(),
                left = self.dummyFrames.left:GetWidth(),
                right = self.dummyFrames.right:GetWidth(),
                bottom = self.dummyFrames.bottom:GetHeight(),
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

    local settings = AuralinVP:GetCurrentSettings()

    self.dummyFrames = {
        left = CreateFrame("Frame", "leftDummyFrame", UIParent),
        right = CreateFrame("Frame", "rightDummyFrame", UIParent),
        top = CreateFrame("Frame", "topDummyFrame", UIParent),
        bottom = CreateFrame("Frame", "bottomDummyFrame", UIParent),
    }
    -- Set positions and sizes based on current settings
    self.dummyFrames.left:SetPoint("LEFT", UIParent, "LEFT", settings.left or 0, 0)
    self.dummyFrames.left:SetSize(settings.left or 1, UIParent:GetHeight())

    self.dummyFrames.right:SetPoint("RIGHT", UIParent, "RIGHT", -(settings.right or 0), 0)
    self.dummyFrames.right:SetSize(settings.right or 1, UIParent:GetHeight())

    self.dummyFrames.top:SetPoint("TOP", UIParent, "TOP", 0, -(settings.top or 0))
    self.dummyFrames.top:SetSize(UIParent:GetWidth(), settings.top or 1)

    self.dummyFrames.bottom:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, settings.bottom or 0)
    self.dummyFrames.bottom:SetSize(UIParent:GetWidth(), settings.bottom or 1)

    -- Hide the frames initially
    for _, frame in pairs(self.dummyFrames) do
        frame:Hide()
        end
    end

-- Function to retrieve current settings
function AuralinVP:GetCurrentSettings()
    return {
        top = self.topSlider and self.topSlider:GetValue() or 0,
        left = self.leftSlider and self.leftSlider:GetValue() or 0,
        right = self.rightSlider and self.rightSlider:GetValue() or 0,
        bottom = self.bottomSlider and self.bottomSlider:GetValue() or 112,
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
