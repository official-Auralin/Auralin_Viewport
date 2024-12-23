local addonName, AuralinVP = ...

AuralinVP.Constants = {
    DEFAULT_TOP = 0,
    DEFAULT_BOTTOM = 112,
    DEFAULT_LEFT = 0,
    DEFAULT_RIGHT = 0,
    ROUNDING_THRESHOLD = 0.5,
    MAX_SLIDER_VALUE = 500,
    DEFAULT_SLIDER_LENGTH = 200,
}
local Constants = AuralinVP.Constants
AuralinVP = AuralinVP or {}

function AuralinVP:ResetDummyFrame(frame, points, size)
    frame:ClearAllPoints()
    for _, point in ipairs(points) do
        frame:SetPoint(unpack(point))
    end
    if size.width then
        frame:SetWidth(size.width)
    elseif size.height then
        frame:SetHeight(size.height)
    end
end

function AuralinVP:RestoreWorldFrame(left, top, right, bottom)
    WorldFrame:ClearAllPoints()
    WorldFrame:SetPoint("TOPLEFT", nil, "TOPLEFT", left, -top)
    WorldFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", -right, bottom)
end

function AuralinVP:GetSettingOrDefault(key)
    return Auralin_Viewport_Settings and Auralin_Viewport_Settings[key] or Constants["DEFAULT_" .. key:upper()]
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
    if not self.dummyFrames or not Auralin_Viewport_Settings then return false end

    local current = {
        top     = self.dummyFrames.top:GetHeight(),
        left    = self.dummyFrames.left:GetWidth(),
        right   = self.dummyFrames.right:GetWidth(),
        bottom  = self.dummyFrames.bottom:GetHeight(),
    }

    local saved = Auralin_Viewport_Settings or { 
        top     = Constants.DEFAULT_TOP, 
        left    = Constants.DEFAULT_LEFT, 
        right   = Constants.DEFAULT_RIGHT, 
        bottom  = Constants.DEFAULT_BOTTOM
    }

    return current.top ~= saved.top or current.left ~= saved.left or
        current.right ~= saved.right or current.bottom ~= saved.bottom
end

-- Function to hide dummy frames upon menu close
function AuralinVP:OnMenuClose()
    if self:ChangesDetected() then
        StaticPopupDialogs["AURALIN_UNSAVED_CHANGES"] = {
            text        = "You have unsaved changes. \nSave & Reload or Cancel to discard changes.",
            button1     = "Save & Reload",
            button2     = "Cancel",
            OnAccept    = function()
                Auralin_Viewport_Settings = {
                    top     = math.floor(self.dummyFrames.top:GetHeight()       + Constants.ROUNDING_THRESHOLD),
                    left    = math.floor(self.dummyFrames.left:GetWidth()       + Constants.ROUNDING_THRESHOLD),
                    right   = math.floor(self.dummyFrames.right:GetWidth()      + Constants.ROUNDING_THRESHOLD),
                    bottom  = math.floor(self.dummyFrames.bottom:GetHeight()    + Constants.ROUNDING_THRESHOLD),
                }
                ReloadUI()
            end,
            OnCancel       = function()
                local top    = Auralin_Viewport_Settings.top or Constants.DEFAULT_TOP
                local bottom = Auralin_Viewport_Settings.bottom or Constants.DEFAULT_BOTTOM
                local left   = Auralin_Viewport_Settings.left or Constants.DEFAULT_LEFT
                local right  = Auralin_Viewport_Settings.right or Constants.DEFAULT_RIGHT

                -- Reset dummy frames
                if AuralinVP.dummyFrames then
                    self:ResetDummyFrame(AuralinVP.dummyFrames.top, {
                        { "TOPLEFT", nil, "TOPLEFT", 0, 0 },
                        { "TOPRIGHT", nil, "TOPRIGHT", 0, 0 },
                    }, { height = top })
                    self:ResetDummyFrame(AuralinVP.dummyFrames.bottom, {
                        { "BOTTOMLEFT", nil, "BOTTOMLEFT", 0, 0 },
                        { "BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, 0 },
                    }, { height = bottom })
                    self:ResetDummyFrame(AuralinVP.dummyFrames.left, {
                        { "TOPLEFT", nil, "TOPLEFT", 0, -top },
                        { "BOTTOMLEFT", nil, "BOTTOMLEFT", 0, bottom },
                    }, { width = left })
                    self:ResetDummyFrame(AuralinVP.dummyFrames.right, {
                        { "TOPRIGHT", nil, "TOPRIGHT", 0, -top },
                        { "BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, bottom },
                    }, { width = right })
                end

                self:RestoreWorldFrame(left, top, right, bottom)
                self:DestroyDummyFrames()
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
        -- No changes detected; clean up
        self:DestroyDummyFrames()
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
