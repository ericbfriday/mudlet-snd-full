-- Set start room for current area
function SnD.Mapper.setStartRoom()
    local roomID = gmcp.room.info.num
    local areaID = getRoomArea(roomID)
    local areaName = getRoomAreaName(areaID)
    
    setAreaUserData(areaID, "SND.startRoom", roomID)
    cecho(string.format("<green>Start room for '%s' set to room %d<reset>", areaName, roomID))
end

-- Navigate to area start room
function SnD.Mapper.xrunto(areaName)
    local areas = getAreaTable()
    local targetAreaID
    
    -- Find area by partial match
    for id, name in pairs(areas) do
        if string.lower(name):find(string.lower(areaName)) then
            targetAreaID = id
            break
        end
    end
    
    if not targetAreaID then
        cecho(string.format("<red>Area '%s' not found in map<reset>", areaName))
        return
    end
    
    local areaData = getAllAreaUserData(targetAreaID)
    local startRoomID = areaData["SND.startRoom"]
    
    if not startRoomID then
        cecho(string.format("<yellow>No start room set for '%s'. Go there and type 'snd setstart'<reset>", areaName))
        return
    end
    
    local currentRoom = gmcp.room.info.num
    local path, cost = mmp.findRoute(currentRoom, startRoomID)
    
    if path and cost > 0 then
        walkTo(path)
        cecho(string.format("<green>Navigating to %s<reset>", areaName))
    else
        cecho("<red>No path found to area start room<reset>")
    end
end