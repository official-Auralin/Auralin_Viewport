local addonName, AuralinVP = ...

-- Add a slash command for showing/hiding the options menu
SLASH_AVP1 = "/avp"
SlashCmdList["AVP"] = function()
    if AuralinVP.MainMenuFrame:IsShown() then
        AuralinVP.MainMenuFrame:Hide()
    else
        AuralinVP.MainMenuFrame:Show()
        UpdateSlidersWithCurrentSettings()
    end
end