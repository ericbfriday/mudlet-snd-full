-- Initialize database
function SnD.Database.init()
    SnD.db = db:create("SND.db", {
        targets = {
            id = "INTEGER PRIMARY KEY",
            name = "TEXT NOT NULL",
            area = "TEXT NOT NULL",
            room_id = "INTEGER",
            mob_vnum = "INTEGER",
            created_at = "DATETIME DEFAULT CURRENT_TIMESTAMP"
        },
        area_starts = {
            area_id = "INTEGER PRIMARY KEY",
            area_name = "TEXT NOT NULL",
            start_room_id = "INTEGER NOT NULL",
            created_at = "DATETIME DEFAULT CURRENT_TIMESTAMP"
        },
        config = {
            key = "TEXT PRIMARY KEY",
            value = "TEXT NOT NULL",
            updated_at = "DATETIME DEFAULT CURRENT_TIMESTAMP"
        }
    })
    cecho("<green>Database initialized<reset>")
end

-- Save campaign targets
function SnD.Database.saveCampaignTargets(targets)
    SnD.db:delete("targets")
    for _, target in ipairs(targets) do
        SnD.db:add("targets", {
            name = target.name,
            area = target.area,
            room_id = target.room_id or 0,
            mob_vnum = target.vnum or 0
        })
    end
    SnD.db:save()
    cecho(string.format("<green>Saved %d campaign targets<reset>", #targets))
end

-- Load campaign targets
function SnD.Database.loadCampaignTargets()
    local targets = {}
    
    for row in SnD.db:nrows("SELECT * FROM targets") do
        table.insert(targets, {
            id = row.id,
            name = row.name,
            area = row.area,
            room_id = row.room_id,
            mob_vnum = row.mob_vnum
        })
    end
    
    return targets
end

-- Load area starts
function SnD.Database.loadAreaStarts()
    local areaStarts = {}
    
    for row in SnD.db:nrows("SELECT * FROM area_starts") do
        areaStarts[row.area_name] = row.start_room_id
    end
    
    return areaStarts
end

-- Save area start
function SnD.Database.saveAreaStart(areaID, startRoomID)
    SnD.db:exec("INSERT OR REPLACE INTO area_starts (area_id, start_room_id) VALUES (?, ?)", 
        areaID, startRoomID)
    cecho(string.format("<green>Area start room saved: %s -> %d<reset>", 
            getRoomAreaName(areaID) or "Unknown", startRoomID))
end

-- Load configuration
function SnD.Database.loadConfig()
    local config = {}
    
    for row in SnD.db:nrows("SELECT * FROM config") do
        config[row.key] = row.value
    end
    
    return config
end

-- Save configuration
function SnD.Database.saveConfig(key, value)
    SnD.db:exec("INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)", 
        key, value)
end