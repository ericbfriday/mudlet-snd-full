-- Enhanced quest handler with real-time processing
SnD.registerHandler("questEnhanced", function()
    local questData = gmcp.comm.quest
    
    if questData.type == "campaign" then
        SnD.state.campaignType = "campaign"
        SnD.state.campaignTargets = questData.targets or {}
        
        -- Update GUI immediately
        SnD.GUI.updateCampaigns(SnD.state.campaignTargets)
        
        -- Save to database
        SnD.Database.saveCampaignTargets(SnD.state.campaignTargets)
        
        -- Notify user
        cecho(string.format("<green>Campaign updated: %d targets<reset>", #SnD.state.campaignTargets))
        
    elseif questData.type == "gquest" then
        SnD.state.campaignType = "gquest"
        SnD.state.gquestTarget = questData.target
        
        cecho(string.format("<cyan>Global Quest: %s<reset>", questData.target.name))
    end
    
    SnD.raiseEvent("campaignDataChanged", questData)
end)