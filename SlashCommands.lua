local addonName, AuralinVP = ...

SLASH_AVP1 = "/avp"
SlashCmdList["AVP"] = function()
    if not AuralinVP.MainMenuFrame then
        AuralinVP:Print("Options frame is not available.")
        return
    end

    if AuralinVP.MainMenuFrame:IsShown() then
        AuralinVP.MainMenuFrame:Hide()
    else
        AuralinVP.MainMenuFrame:Show()
    end
end
