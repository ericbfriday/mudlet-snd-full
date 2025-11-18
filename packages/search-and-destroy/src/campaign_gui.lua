-- Update campaign display
function SnD.GUI.updateCampaigns(targets)
    -- Clear existing labels
    for _, label in ipairs(SnD.GUI.campaignLabels or {}) do
        label:hide()
        label:delete()
    end
    SnD.GUI.campaignLabels = {}
    
    -- Create new target labels
    for i, target in ipairs(targets) do
        local label = Geyser.Label:new({
            name = "SND_Target_" .. i,
            text = string.format("%d. %s (%s)", i, target.name, target.area),
            color = "white",
            fontSize = 10,
            clickFunction = function()
                SnD.Mapper.xrunto(target.area)
                SnD.QuickWhere.execute(target.name)
            end
        }, SnD.GUI.campaignContainer)
        
        label:setToolTip(string.format("Click to navigate to %s in %s", target.name, target.area))
        table.insert(SnD.GUI.campaignLabels, label)
    end
end

-- Register for campaign updates
SnD.registerHandler("campaignsUpdated", SnD.GUI.updateCampaigns)