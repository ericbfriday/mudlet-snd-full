-- Room info update handler
SnD.registerHandler("roomUpdated", function()
    SnD.state.currentRoom = gmcp.room.info
    SnD.raiseEvent("locationChanged", SnD.state.currentRoom)
end)

-- Campaign/quest data handler
SnD.registerHandler("questUpdated", function()
    if gmcp.comm.quest and gmcp.comm.quest.targets then
        SnD.state.campaignTargets = gmcp.comm.quest.targets
        SnD.Database.saveCampaignTargets(SnD.state.campaignTargets)
        SnD.raiseEvent("campaignsUpdated", SnD.state.campaignTargets)
    end
end)

-- Register GMCP event handlers
registerAnonymousEventHandler("gmcp.room.info", SnD.handlers.roomUpdated)
registerAnonymousEventHandler("gmcp.comm.quest", SnD.handlers.questUpdated)