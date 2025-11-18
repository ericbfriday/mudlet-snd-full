-- Hunt trick state
SnD.Hunt = SnD.Hunt or {
    active = false,
    baseMob = "",
    currentIndex = 1,
    lastMob = ""
}

-- Execute hunt trick sequence
function SnD.Hunt.execute(mob, startIndex)
    if not mob or mob == "" then
        mob = SnD.Hunt.lastMob
    end
    
    if not mob then
        cecho("<yellow>No mob specified. Use 'ht <mob>' to start hunting<reset>")
        return
    end
    
    SnD.Hunt.baseMob = mob
    SnD.Hunt.currentIndex = startIndex or 1
    SnD.Hunt.active = true
    SnD.Hunt.lastMob = mob
    
    cecho(string.format("<green>Hunt trick started: %s<reset>", mob))
    SnD.Hunt.next()
end

-- Hunt next instance
function SnD.Hunt.next()
    if not SnD.Hunt.active then return end
    
    local huntTarget = string.format("%d.%s", SnD.Hunt.currentIndex, SnD.Hunt.baseMob)
    send("hunt " .. huntTarget)
    
    -- Create trigger to check result
    tempRegexTrigger("^You cannot hunt that\\.$", function()
        cecho(string.format("<yellow>No more instances of %s found<reset>", SnD.Hunt.baseMob))
        SnD.Hunt.active = false
        SnD.raiseEvent("huntCompleted", {mob = SnD.Hunt.baseMob, found = false})
    end, 1)
    
    tempRegexTrigger("^You are now hunting (.+)\\.$", function()
        cecho(string.format("<green>Now hunting: %s<reset>", matches[2]))
        SnD.Hunt.currentIndex = SnD.Hunt.currentIndex + 1
        tempTimer(1.0, SnD.Hunt.next)
    end, 1)
    
    tempRegexTrigger("^(.+) is (here|close by)$", function()
        cecho(string.format("<green>Found: %s<reset>", matches[2]))
        SnD.Hunt.active = false
        SnD.Hunt.lastMob = SnD.Hunt.baseMob
        SnD.raiseEvent("huntCompleted", {mob = SnD.Hunt.baseMob, found = true})
    end, 1)
end

-- Abort hunt trick
function SnD.Hunt.abort()
    if SnD.Hunt.active then
        SnD.Hunt.active = false
        cecho("<red>Hunt trick aborted<reset>")
        SnD.raiseEvent("huntAborted", {})
    end
end