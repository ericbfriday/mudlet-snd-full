-- Quick where functionality
SnD.QuickWhere = SnD.QuickWhere or {}

-- Execute quick where command
function SnD.QuickWhere.execute(mob)
    if not mob or mob == "" then
        cecho("<yellow>No mob specified for quick where<reset>")
        return
    end
    
    -- Send where command
    send("where " .. mob)
    
    -- Create trigger to capture response
    tempRegexTrigger("^(.+) is (somewhere|close by)$", function(matches)
        local mobName = matches[2]
        cecho(string.format("<green>Found: %s<reset>", mobName))
        
        -- Search for room in mapper
        local areas = getAreaTable()
        local foundRoom = nil
        
        for areaID, areaName in pairs(areas) do
            local rooms = getAreaRooms(areaID)
            if rooms then
                for _, roomID in ipairs(rooms) do
                    local roomName = getRoomName(roomID)
                    if roomName and string.lower(roomName):find(string.lower(mobName)) then
                        foundRoom = roomID
                        break
                    end
                end
            end
            if foundRoom then break end
        end
        
        if foundRoom then
            cecho(string.format("<cyan>Room found: %s (ID: %d)<reset>", getRoomName(foundRoom), foundRoom))
        else
            cecho(string.format("<yellow>Room not found for: %s<reset>", mob))
        end
    end
    end, 1)
end