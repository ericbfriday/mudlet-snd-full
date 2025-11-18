-- List campaign targets
function SnD.Campaign.list()
    local targets = SnD.state.campaignTargets or {}
    
    if #targets == 0 then
        cecho("<yellow>No active campaign targets found<reset>")
        return
    end
    
    cecho("<green>Campaign Targets:<reset>")
    for i, target in ipairs(targets) do
        cecho(string.format("  %d. %s (%s)", i, target.name, target.area))
    end
    cecho("<cyan>Use 'xcp <number>' to navigate to target<reset>")
end

-- Navigate to campaign target
function SnD.Campaign.gotoTarget(index)
    local targets = SnD.state.campaignTargets or {}
    local target = targets[index]
    
    if not target then
        cecho(string.format("<red>Invalid target index: %d<reset>", index))
        return
    end
    
    -- Navigate to area first
    SnD.Mapper.xrunto(target.area)
    
    -- Then search for mob in area
    tempTimer(2.0, function()
        SnD.QuickWhere.execute(target.name)
    end)
end

-- Process xcp command
function SnD.Campaign.process(input)
    if not input or input == "" then
        SnD.Campaign.list()
        return
    end
    
    local index = tonumber(input)
    if index then
        SnD.Campaign.gotoTarget(index)
    else
        cecho("<cyan>Usage: xcp [number] - Navigate to campaign target<reset>")
    end
end