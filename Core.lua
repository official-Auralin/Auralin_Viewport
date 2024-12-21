local addonName, AuralinVP = ...

-- Define global variables
AuralinVP = AuralinVP or {}
AuralinVP.MainMenuFrame = CreateFrame("Frame", "MainMenuFrame", UIParent, "BasicFrameTemplateWithInset")
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

-- Function to hide dummy frames upon menu close
function AuralinVP:OnMenuClose()
    if AuralinVP:ChangesDetected() then
        StaticPopupDialogs["AURALIN_UNSAVED_CHANGES"] = {
            text = "You have unsaved changes. \nSave & Reload or Cancel to discard changes.",
            button1 = "Save & Reload",
            button2 = "Cancel",
            OnAccept = function()
                -- Save current dummy frame settings
                Auralin_Viewport_Settings = {
                    top = self.dummyFrames.top:GetHeight(),
                    left = self.dummyFrames.left:GetWidth(),
                    right = self.dummyFrames.right:GetWidth(),
                    bottom = self.dummyFrames.bottom:GetHeight(),
                }
                ReloadUI()
            end,
            OnCancel = function()
                AuralinVP:DestroyDummyFrames()
                -- Then close the menu frame
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
        AuralinVP:DestroyDummyFrames()
        if AuralinVP.MainMenuFrame then
            AuralinVP.MainMenuFrame:Hide()
        end
    end
end

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
