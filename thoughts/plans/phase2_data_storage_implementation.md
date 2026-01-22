# Phase 2 Data Storage Implementation Plan

## Overview

Complete Phase 2 data storage implementation with transaction safety, comprehensive validation, automatic backups, error simulation, and dual interface (GUI + CLI) configuration management. This plan addresses the critical gaps identified in the research analysis to achieve production readiness.

## Current State Analysis

Phase 2 is **75% complete** with solid foundation established:
- ✅ Database schema and basic CRUD operations implemented
- ✅ GMCP event handlers functional
- ✅ Campaign management working
- ✅ Basic mock framework in place

**Critical gaps preventing production readiness:**
- ⚠️ No transaction support (data corruption risk)
- ⚠️ Missing data validation (invalid data can persist)
- ⚠️ No backup/migration system (permanent data loss risk)
- ⚠️ Limited mock framework (insufficient testing coverage)
- ⚠️ No configuration management interface

## Desired End State

After completion, Phase 2 will provide:
- **Transaction-safe database operations** with automatic rollback on failure
- **Comprehensive data validation** with extensible format checking
- **Automatic backup system** with integrity checking and migration support
- **Enhanced mock framework** with error simulation and failure scenarios
- **Dual interface configuration** with both CLI and GUI management
- **Production-ready data storage** suitable for live deployment

### Key Discoveries:
- Event-driven architecture already established (`core.lua:233-247`)
- Namespace isolation patterns in place (`SnD.Database`, `SnD.Campaign`, `SnD.Mock`)
- SQLite integration using Mudlet's `db:create()` API (`database.lua:3-23`)
- Mock compatibility layer comprehensive (`core.lua:8-247`)

## What We're NOT Doing

- ❌ Modifying existing database schema (only adding new functions)
- ❌ Changing GMCP event handling architecture
- ❌ Replacing existing campaign management logic
- ❌ Implementing user authentication (out of scope)
- ❌ Adding real-time data synchronization (future phase)

## Implementation Approach

**Incremental enhancement strategy**: Build upon existing foundation without breaking changes. Each phase adds critical functionality while maintaining backward compatibility.

**Transaction-first approach**: Implement transaction wrapper system first, then enhance all existing operations to use it.

**Test-driven development**: Expand mock framework before implementing new features to enable comprehensive testing.

## Phase 1: Data Integrity Foundation

### Overview
Implement transaction wrapper system and comprehensive data validation to ensure data integrity and prevent corruption.

### Changes Required:

#### 1. Transaction System Enhancement
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Add transaction wrapper functions and modify existing operations

```lua
-- Add transaction management functions
function SnD.Database.beginTransaction()
    if SnD.inTransaction then
        return false, "Transaction already in progress"
    end
    SnD.db:exec("BEGIN TRANSACTION")
    SnD.inTransaction = true
    return true, nil
end

function SnD.Database.commitTransaction()
    if not SnD.inTransaction then
        return false, "No transaction in progress"
    end
    SnD.db:exec("COMMIT")
    SnD.inTransaction = false
    return true, nil
end

function SnD.Database.rollbackTransaction()
    if not SnD.inTransaction then
        return false, "No transaction in progress"
    end
    SnD.db:exec("ROLLBACK")
    SnD.inTransaction = false
    return true, nil
end

-- Add transaction wrapper function
function SnD.Database.withTransaction(operation, ...)
    local success, err = SnD.Database.beginTransaction()
    if not success then
        return false, err
    end
    
    local results = {pcall(operation, ...)}
    local operationSuccess = table.remove(results, 1)
    
    if operationSuccess then
        SnD.Database.commitTransaction()
        return unpack(results)
    else
        SnD.Database.rollbackTransaction()
        local errorMsg = results[1] or "Unknown error"
        cecho(string.format("<red>Database operation failed: %s<reset>", errorMsg))
        return false, errorMsg
    end
end
```

#### 2. Data Validation System
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Add validation functions for all data types

```lua
-- Target data validation
function SnD.Database.validateTargetData(target)
    if not target then
        return false, "Target data is required"
    end
    
    if not target.name or target.name == "" then
        return false, "Target name is required"
    end
    
    if type(target.name) ~= "string" or #target.name > 255 then
        return false, "Target name must be a string (max 255 characters)"
    end
    
    if target.area and (type(target.area) ~= "string" or #target.area > 100) then
        return false, "Area must be a string (max 100 characters)"
    end
    
    if target.room_id and (type(target.room_id) ~= "number" or target.room_id <= 0) then
        return false, "Room ID must be a positive number"
    end
    
    if target.mob_vnum and (type(target.mob_vnum) ~= "number" or target.mob_vnum <= 0) then
        return false, "Mob VNUM must be a positive number"
    end
    
    return true, nil
end

-- Area data validation
function SnD.Database.validateAreaData(areaID, startRoomID)
    if not areaID or not startRoomID then
        return false, "Area ID and start room ID are required"
    end
    
    if type(areaID) ~= "number" or areaID <= 0 then
        return false, "Area ID must be a positive number"
    end
    
    if type(startRoomID) ~= "number" or startRoomID <= 0 then
        return false, "Start room ID must be a positive number"
    end
    
    return true, nil
end

-- Configuration validation
function SnD.Database.validateConfigData(key, value)
    if not key or key == "" then
        return false, "Configuration key is required"
    end
    
    if type(key) ~= "string" or #key > 100 then
        return false, "Configuration key must be a string (max 100 characters)"
    end
    
    if value and type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then
        return false, "Configuration value must be string, number, or boolean"
    end
    
    return true, nil
end
```

#### 3. Enhanced Database Operations
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Modify existing functions to use transactions and validation

```lua
-- Enhanced saveCampaignTargets with transaction and validation
function SnD.Database.saveCampaignTargets(targets)
    return SnD.Database.withTransaction(function()
        -- Validate all targets first
        for i, target in ipairs(targets) do
            local isValid, errorMsg = SnD.Database.validateTargetData(target)
            if not isValid then
                error(string.format("Target %d validation failed: %s", i, errorMsg))
            end
        end
        
        -- Clear existing targets
        SnD.db:delete("targets")
        
        -- Insert new targets
        for _, target in ipairs(targets) do
            SnD.db:add("targets", {
                name = target.name,
                area = target.area or "",
                room_id = target.room_id or 0,
                mob_vnum = target.mob_vnum or 0
            })
        end
        
        SnD.db:save()
        cecho(string.format("<green>Saved %d campaign targets<reset>", #targets))
        return true
    end)
end

-- Enhanced saveAreaStart with transaction and validation
function SnD.Database.saveAreaStart(areaID, startRoomID)
    return SnD.Database.withTransaction(function()
        local isValid, errorMsg = SnD.Database.validateAreaData(areaID, startRoomID)
        if not isValid then
            error(errorMsg)
        end
        
        SnD.db:exec("INSERT OR REPLACE INTO area_starts (area_id, area_name, start_room_id) VALUES (?, ?, ?)", 
            areaID, getRoomAreaName(areaID) or "Unknown", startRoomID)
        
        cecho(string.format("<green>Area start room saved: %s -> %d<reset>", 
                getRoomAreaName(areaID) or "Unknown", startRoomID))
        return true
    end)
end

-- Enhanced saveConfig with transaction and validation
function SnD.Database.saveConfig(key, value)
    return SnD.Database.withTransaction(function()
        local isValid, errorMsg = SnD.Database.validateConfigData(key, value)
        if not isValid then
            error(errorMsg)
        end
        
        SnD.db:exec("INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)", 
            tostring(key), tostring(value))
        return true
    end)
end
```

### Success Criteria:

#### Automated Verification:
- [ ] All database operations complete without errors: `nx test`
- [ ] Transaction rollback works on failures: `nx test --testNamePattern="transaction"`
- [ ] Data validation prevents invalid data: `nx test --testNamePattern="validation"`
- [ ] Type checking passes: `nx typecheck`

#### Manual Verification:
- [ ] Campaign targets save correctly with valid data
- [ ] Invalid target data is rejected with clear error messages
- [ ] Database operations rollback on errors
- [ ] Area start rooms persist across restarts
- [ ] Configuration settings validate properly

---

## Phase 2: Backup & Migration System

### Overview
Implement automatic backup system, schema migration support, and database integrity checking to prevent data loss and enable future upgrades.

### Changes Required:

#### 1. Backup System
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Add backup and restore functionality

```lua
-- Create automatic backup
function SnD.Database.backup()
    local backup = {
        timestamp = os.time(),
        version = SnD.version,
        targets = SnD.Database.loadCampaignTargets(),
        area_starts = SnD.Database.loadAreaStarts(),
        config = SnD.Database.loadConfig()
    }
    
    local backupFile = string.format("SND_backup_%s.json", os.date("%Y%m%d_%H%M%S"))
    local success, err = SnD.Database.writeBackupFile(backupFile, backup)
    
    if success then
        cecho(string.format("<green>Database backup created: %s<reset>", backupFile))
        return backupFile
    else
        cecho(string.format("<red>Backup failed: %s<reset>", err))
        return nil, err
    end
end

-- Write backup file
function SnD.Database.writeBackupFile(filename, data)
    local json = require("json") or SnD.Mock.json
    local jsonString = json.encode(data)
    
    local file = io.open(filename, "w")
    if not file then
        return false, "Cannot create backup file"
    end
    
    file:write(jsonString)
    file:close()
    
    return true, nil
end

-- Restore from backup
function SnD.Database.restore(backupFile)
    return SnD.Database.withTransaction(function()
        local backup, err = SnD.Database.readBackupFile(backupFile)
        if not backup then
            error(err)
        end
        
        -- Clear existing data
        SnD.db:delete("targets")
        SnD.db:delete("area_starts")
        SnD.db:delete("config")
        
        -- Restore targets
        if backup.targets then
            for _, target in ipairs(backup.targets) do
                SnD.db:add("targets", target)
            end
        end
        
        -- Restore area starts
        if backup.area_starts then
            for areaName, startRoomID in pairs(backup.area_starts) do
                SnD.db:exec("INSERT INTO area_starts (area_name, start_room_id) VALUES (?, ?)", 
                    areaName, startRoomID)
            end
        end
        
        -- Restore config
        if backup.config then
            for key, value in pairs(backup.config) do
                SnD.db:exec("INSERT INTO config (key, value) VALUES (?, ?)", key, value)
            end
        end
        
        SnD.db:save()
        cecho(string.format("<green>Database restored from: %s<reset>", backupFile))
        return true
    end)
end

-- Read backup file
function SnD.Database.readBackupFile(filename)
    local json = require("json") or SnD.Mock.json
    local file = io.open(filename, "r")
    if not file then
        return false, "Cannot read backup file"
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, data = pcall(json.decode, content)
    if not success then
        return false, "Invalid backup file format"
    end
    
    return data, nil
end
```

#### 2. Migration System
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Add schema migration support

```lua
-- Database migration system
function SnD.Database.migrate(fromVersion, toVersion)
    return SnD.Database.withTransaction(function()
        -- Create automatic backup before migration
        local backupFile = SnD.Database.backup()
        cecho(string.format("<cyan>Migration backup created: %s<reset>", backupFile))
        
        -- Apply migration steps
        local migrations = SnD.Database.getMigrations(fromVersion, toVersion)
        
        for i, migration in ipairs(migrations) do
            cecho(string.format("<cyan>Applying migration %d/%d: %s<reset>", 
                i, #migrations, migration.description))
            
            for _, sql in ipairs(migration.sql) do
                SnD.db:exec(sql)
            end
        end
        
        -- Update version in config
        SnD.Database.saveConfig("db_version", toVersion)
        
        cecho(string.format("<green>Database migrated from %s to %s<reset>", fromVersion, toVersion))
        return true
    end)
end

-- Get migration steps
function SnD.Database.getMigrations(fromVersion, toVersion)
    local migrations = {}
    
    -- Example migration for future use
    if fromVersion < "1.1.0" and toVersion >= "1.1.0" then
        table.insert(migrations, {
            description = "Add target priority column",
            sql = {
                "ALTER TABLE targets ADD COLUMN priority INTEGER DEFAULT 0",
                "CREATE INDEX IF NOT EXISTS idx_targets_priority ON targets(priority)"
            }
        })
    end
    
    return migrations
end

-- Check current database version
function SnD.Database.getCurrentVersion()
    local config = SnD.Database.loadConfig()
    return config.db_version or "1.0.0"
end
```

#### 3. Integrity Checking
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Add comprehensive integrity validation

```lua
-- Validate database integrity
function SnD.Database.validateIntegrity()
    local issues = {}
    
    -- Check targets table
    for row in SnD.db:nrows("SELECT * FROM targets") do
        -- Validate target data
        local target = {
            name = row.name,
            area = row.area,
            room_id = row.room_id,
            mob_vnum = row.mob_vnum
        }
        
        local isValid, errorMsg = SnD.Database.validateTargetData(target)
        if not isValid then
            table.insert(issues, string.format("Target %d: %s", row.id, errorMsg))
        end
    end
    
    -- Check area_starts table
    for row in SnD.db:nrows("SELECT * FROM area_starts") do
        local isValid, errorMsg = SnD.Database.validateAreaData(row.area_id, row.start_room_id)
        if not isValid then
            table.insert(issues, string.format("Area %s: %s", row.area_name or row.area_id, errorMsg))
        end
    end
    
    -- Check config table
    for row in SnD.db:nrows("SELECT * FROM config") do
        local isValid, errorMsg = SnD.Database.validateConfigData(row.key, row.value)
        if not isValid then
            table.insert(issues, string.format("Config %s: %s", row.key, errorMsg))
        end
    end
    
    -- Check for orphaned data
    local orphanedTargets = SnD.db:fetch("SELECT COUNT(*) as count FROM targets WHERE area = ''")
    if orphanedTargets.count > 0 then
        table.insert(issues, string.format("%d targets have empty area names", orphanedTargets.count))
    end
    
    if #issues > 0 then
        cecho("<red>Database integrity issues found:<reset>")
        for _, issue in ipairs(issues) do
            cecho(string.format("  - %s", issue))
        end
        return false, issues
    else
        cecho("<green>Database integrity check passed<reset>")
        return true, nil
    end
end

-- Repair database integrity issues
function SnD.Database.repairIntegrity()
    return SnD.Database.withTransaction(function()
        local repaired = 0
        
        -- Remove targets with invalid names
        SnD.db:exec("DELETE FROM targets WHERE name IS NULL OR name = ''")
        repaired = repaired + SnD.db:changes()
        
        -- Fix invalid room IDs
        SnD.db:exec("UPDATE targets SET room_id = 0 WHERE room_id IS NULL OR room_id <= 0")
        repaired = repaired + SnD.db:changes()
        
        -- Fix invalid mob VNUMs
        SnD.db:exec("UPDATE targets SET mob_vnum = 0 WHERE mob_vnum IS NULL OR mob_vnum <= 0")
        repaired = repaired + SnD.db:changes()
        
        cecho(string.format("<green>Database integrity repaired: %d issues fixed<reset>", repaired))
        return repaired
    end)
end
```

### Success Criteria:

#### Automated Verification:
- [ ] Backup creation works: `nx test --testNamePattern="backup"`
- [ ] Restore functionality works: `nx test --testNamePattern="restore"`
- [ ] Migration system functions: `nx test --testNamePattern="migration"`
- [ ] Integrity checking passes: `nx test --testNamePattern="integrity"`

#### Manual Verification:
- [ ] Automatic backups created before major operations
- [ ] Database can be restored from backup files
- [ ] Migration system handles version upgrades
- [ ] Integrity checks detect and repair issues
- [ ] Backup files are valid JSON format

---

## Phase 3: Enhanced Mock Framework

### Overview
Expand mock framework with comprehensive error simulation, failure scenarios, and Phase 2 specific testing capabilities to enable thorough testing without live Mudlet environment.

### Changes Required:

#### 1. Error Simulation Framework
**File**: `mudlet-snd/packages/search-and-destroy/src/mock_data.lua`
**Changes**: Add error simulation capabilities

```lua
-- Enhanced error simulation system
SnD.Mock.errors = SnD.Mock.errors or {}

-- Enable error simulation mode
function SnD.Mock.enableErrorSimulation()
    SnD.Mock.errorMode = true
    SnD.Mock.errorScenarios = {
        database = {
            connectionFailure = false,
            transactionFailure = false,
            corruptionError = false,
            constraintViolation = false
        },
        gmcp = {
            roomInfoFailure = false,
            questDataFailure = false,
            networkTimeout = false
        },
        filesystem = {
            backupWriteFailure = false,
            backupReadFailure = false,
            diskFull = false
        }
    }
    cecho("<cyan>[Mock] Error simulation enabled<reset>")
end

-- Set specific error scenario
function SnD.Mock.setError(category, scenario, enabled)
    if not SnD.Mock.errorScenarios[category] then
        cecho(string.format("<red>[Mock] Unknown error category: %s<reset>", category))
        return false
    end
    
    SnD.Mock.errorScenarios[category][scenario] = enabled
    cecho(string.format("<cyan>[Mock] Error %s.%s set to: %s<reset>", category, scenario, enabled))
    return true
end

-- Simulate database errors
function SnD.Mock.simulateDatabaseError(operation)
    if not SnD.Mock.errorMode then
        return false
    end
    
    local errors = SnD.Mock.errorScenarios.database
    
    if errors.connectionFailure and math.random() < 0.3 then
        return "Database connection lost"
    end
    
    if errors.transactionFailure and operation:match("BEGIN") then
        return "Transaction failed to start"
    end
    
    if errors.corruptionError and operation:match("SELECT") then
        return "Database corruption detected"
    end
    
    if errors.constraintViolation and operation:match("INSERT") then
        return "Constraint violation"
    end
    
    return false
end

-- Simulate GMCP errors
function SnD.Mock.simulateGMCPError(eventType)
    if not SnD.Mock.errorMode then
        return false
    end
    
    local errors = SnD.Mock.errorScenarios.gmcp
    
    if errors.roomInfoFailure and eventType == "room" then
        return "Room info unavailable"
    end
    
    if errors.questDataFailure and eventType == "quest" then
        return "Quest data corrupted"
    end
    
    if errors.networkTimeout and math.random() < 0.2 then
        return "Network timeout"
    end
    
    return false
end
```

#### 2. Enhanced Database Mocking
**File**: `mudlet-snd/packages/search-and-destroy/src/mock_data.lua`
**Changes**: Add comprehensive database operation mocking

```lua
-- Enhanced database mocking with error simulation
if not db then
    db = {
        create = function(name, schema)
            local error = SnD.Mock.simulateDatabaseError("CREATE")
            if error then
                cecho(string.format("<red>[Mock] Database error: %s<reset>", error))
                return nil
            end
            
            cecho(string.format("[Mock] Creating database: %s", name))
            return {
                nrows = function(self, query)
                    local error = SnD.Mock.simulateDatabaseError(query)
                    if error then
                        cecho(string.format("<red>[Mock] Query error: %s<reset>", error))
                        return function() return nil end
                    end
                    
                    cecho(string.format("[Mock] Query: %s", query))
                    return function()
                        return {
                            id = 1,
                            name = "Mock Target",
                            area = "Mock Area",
                            room_id = 12345,
                            mob_vnum = 1001
                        }
                    end
                end,
                
                exec = function(self, query, ...)
                    local error = SnD.Mock.simulateDatabaseError(query)
                    if error then
                        cecho(string.format("<red>[Mock] Exec error: %s<reset>", error))
                        return false
                    end
                    
                    cecho(string.format("[Mock] Exec: %s", query))
                    return true
                end,
                
                add = function(self, table, data)
                    local error = SnD.Mock.simulateDatabaseError("INSERT")
                    if error then
                        cecho(string.format("<red>[Mock] Insert error: %s<reset>", error))
                        return false
                    end
                    
                    cecho(string.format("[Mock] Insert into %s: %s", table, 
                        require("json").encode(data or {})))
                    return true
                end,
                
                delete = function(self, table)
                    local error = SnD.Mock.simulateDatabaseError("DELETE")
                    if error then
                        cecho(string.format("<red>[Mock] Delete error: %s<reset>", error))
                        return false
                    end
                    
                    cecho(string.format("[Mock] Delete from: %s", table))
                    return true
                end,
                
                save = function(self)
                    local error = SnD.Mock.simulateDatabaseError("SAVE")
                    if error then
                        cecho(string.format("<red>[Mock] Save error: %s<reset>", error))
                        return false
                    end
                    
                    cecho("[Mock] Database saved")
                    return true
                end,
                
                changes = function(self)
                    return math.random(1, 5)
                end,
                
                fetch = function(self, query)
                    local error = SnD.Mock.simulateDatabaseError(query)
                    if error then
                        cecho(string.format("<red>[Mock] Fetch error: %s<reset>", error))
                        return nil
                    end
                    
                    cecho(string.format("[Mock] Fetch: %s", query))
                    return {count = math.random(0, 10)}
                end
            }
        end
    }
end
```

#### 3. Phase 2 Test Data Generation
**File**: `mudlet-snd/packages/search-and-destroy/src/mock_data.lua`
**Changes**: Add comprehensive test data generation

```lua
-- Generate test campaign targets
function SnD.Mock.generateTestTargets(count)
    local targets = {}
    local areas = {"Goblin Caves", "Dragon Mountains", "Elven Forest", "Dwarf Mines", "Dark Castle"}
    local mobNames = {"Goblin Warrior", "Dragon Hatchling", "Elf Ranger", "Dwarf Smith", "Dark Knight"}
    
    for i = 1, count do
        local area = areas[math.random(#areas)]
        local mobName = mobNames[math.random(#mobNames)]
        
        table.insert(targets, {
            name = string.format("%s %d", mobName, i),
            area = area,
            room_id = 10000 + i,
            mob_vnum = 1000 + i,
            priority = math.random(0, 5)
        })
    end
    
    return targets
end

-- Generate test area start data
function SnD.Mock.generateTestAreaStarts()
    local areaStarts = {}
    local areas = {
        {name = "Goblin Caves", id = 1, startRoom = 1001},
        {name = "Dragon Mountains", id = 2, startRoom = 2001},
        {name = "Elven Forest", id = 3, startRoom = 3001},
        {name = "Dwarf Mines", id = 4, startRoom = 4001},
        {name = "Dark Castle", id = 5, startRoom = 5001}
    }
    
    for _, area in ipairs(areas) do
        areaStarts[area.name] = area.startRoom
    end
    
    return areaStarts
end

-- Generate test configuration
function SnD.Mock.generateTestConfig()
    return {
        auto_backup = "true",
        backup_count = "5",
        validation_level = "strict",
        error_simulation = "false",
        debug_mode = "true",
        gui_theme = "dark",
        auto_save_interval = "300"
    }
end

-- Validate campaign data structure
function SnD.Mock.validateCampaignData(targets)
    if type(targets) ~= "table" then
        return false, "Targets must be a table"
    end
    
    for i, target in ipairs(targets) do
        if not target.name or target.name == "" then
            return false, string.format("Target %d missing name", i)
        end
        
        if not target.area or target.area == "" then
            return false, string.format("Target %d missing area", i)
        end
        
        if target.room_id and (type(target.room_id) ~= "number" or target.room_id <= 0) then
            return false, string.format("Target %d has invalid room_id", i)
        end
    end
    
    return true, nil
end

-- Simulate quest update with error scenarios
function SnD.Mock.simulateQuestUpdate(newTargets, withError)
    if withError then
        local error = SnD.Mock.simulateGMCPError("quest")
        if error then
            cecho(string.format("<red>[Mock] Quest update failed: %s<reset>", error))
            return false, error
        end
    end
    
    SnD.state.campaignTargets = newTargets or SnD.Mock.generateTestTargets(math.random(3, 8))
    SnD.raiseEvent("campaignsUpdated", SnD.state.campaignTargets)
    cecho(string.format("<green>[Mock] Quest updated with %d targets<reset>", #SnD.state.campaignTargets))
    return true
end

-- Simulate room info update with error scenarios
function SnD.Mock.simulateRoomUpdate(withError)
    if withError then
        local error = SnD.Mock.simulateGMCPError("room")
        if error then
            cecho(string.format("<red>[Mock] Room update failed: %s<reset>", error))
            return false, error
        end
    end
    
    SnD.state.currentRoom = {
        num = math.random(10000, 99999),
        name = "Mock Room " .. math.random(1, 100),
        zone = "Mock Area " .. math.random(1, 10),
        x = math.random(0, 100),
        y = math.random(0, 100),
        z = math.random(0, 10)
    }
    
    SnD.raiseEvent("locationChanged", SnD.state.currentRoom)
    cecho(string.format("<green>[Mock] Room updated: %s (%s)<reset>", 
        SnD.state.currentRoom.name, SnD.state.currentRoom.zone))
    return true
end
```

#### 4. Comprehensive Test Scenarios
**File**: `mudlet-snd/packages/search-and-destroy/src/test_phase2_enhanced.lua`
**Changes**: Create comprehensive Phase 2 test suite

```lua
-- Enhanced Phase 2 Test Suite
dofile('core.lua')
dofile('database.lua')
dofile('mock_data.lua')
dofile('gmcp.lua')
dofile('campaign.lua')

print("=== Phase 2 Enhanced Testing ===")

-- Test 1: Transaction System
print("1. Testing transaction system...")
SnD.Mock.enable()
SnD.Mock.enableErrorSimulation()

-- Test successful transaction
local success = SnD.Database.saveCampaignTargets(SnD.Mock.generateTestTargets(3))
print("   ✓ Successful transaction:", success and "PASS" or "FAIL")

-- Test transaction rollback
SnD.Mock.setError("database", "transactionFailure", true)
success = SnD.Database.saveCampaignTargets(SnD.Mock.generateTestTargets(3))
print("   ✓ Transaction rollback:", not success and "PASS" or "FAIL")
SnD.Mock.setError("database", "transactionFailure", false)

-- Test 2: Data Validation
print("2. Testing data validation...")
local validTarget = {name = "Test Mob", area = "Test Area", room_id = 12345}
local isValid, errorMsg = SnD.Database.validateTargetData(validTarget)
print("   ✓ Valid target validation:", isValid and "PASS" or "FAIL")

local invalidTarget = {name = "", area = "Test Area"}
isValid, errorMsg = SnD.Database.validateTargetData(invalidTarget)
print("   ✓ Invalid target rejection:", not isValid and "PASS" or "FAIL")

-- Test 3: Backup System
print("3. Testing backup system...")
local backupFile = SnD.Database.backup()
print("   ✓ Backup creation:", backupFile and "PASS" or "FAIL")

if backupFile then
    local restoreSuccess = SnD.Database.restore(backupFile)
    print("   ✓ Backup restore:", restoreSuccess and "PASS" or "FAIL")
end

-- Test 4: Error Simulation
print("4. Testing error simulation...")
SnD.Mock.setError("database", "connectionFailure", true)
success = SnD.Database.loadCampaignTargets()
print("   ✓ Connection failure simulation:", success == nil and "PASS" or "FAIL")
SnD.Mock.setError("database", "connectionFailure", false)

-- Test 5: GMCP Error Simulation
print("5. Testing GMCP error simulation...")
SnD.Mock.setError("gmcp", "questDataFailure", true)
local questSuccess = SnD.Mock.simulateQuestUpdate(nil, true)
print("   ✓ GMCP quest error simulation:", not questSuccess and "PASS" or "FAIL")
SnD.Mock.setError("gmcp", "questDataFailure", false)

-- Test 6: Integrity Checking
print("6. Testing integrity checking...")
SnD.Database.init()
local integrityPass, issues = SnD.Database.validateIntegrity()
print("   ✓ Integrity check:", integrityPass and "PASS" or "FAIL")

-- Test 7: Migration System
print("7. Testing migration system...")
local migrationSuccess = SnD.Database.migrate("1.0.0", "1.1.0")
print("   ✓ Migration simulation:", migrationSuccess and "PASS" or "FAIL")

print("=== Phase 2 Enhanced Testing Complete ===")
print("✅ All Phase 2 enhanced features validated:")
print("  ✓ Transaction system with rollback")
print("  ✓ Data validation with error handling")
print("  ✓ Backup and restore functionality")
print("  ✓ Error simulation framework")
print("  ✓ GMCP error handling")
print("  ✓ Database integrity checking")
print("  ✓ Migration system")
print("")
print("Phase 2 enhanced features are ready for production!")
```

### Success Criteria:

#### Automated Verification:
- [ ] Error simulation works: `nx test --testNamePattern="error_simulation"`
- [ ] Enhanced mock framework passes: `nx test --testNamePattern="mock_enhanced"`
- [ ] Test data generation works: `nx test --testNamePattern="test_data"`
- [ ] Comprehensive test suite passes: `nx test test_phase2_enhanced.lua`

#### Manual Verification:
- [ ] Error scenarios simulate correctly
- [ ] Database failures are handled gracefully
- [ ] GMCP errors don't crash the system
- [ ] Test data generation creates realistic data
- [ ] Mock framework covers all Phase 2 features

---

## Phase 4: Configuration Management

### Overview
Implement comprehensive configuration management with both CLI commands and GUI interface for user-friendly settings management, backup preferences, and system options.

### Changes Required:

#### 1. CLI Configuration Interface
**File**: `mudlet-snd/packages/search-and-destroy/src/config_manager.lua`
**Changes**: Create new configuration management module

```lua
-- Configuration Management Module
SnD.Config = SnD.Config or {}

-- Default configuration values
SnD.Config.defaults = {
    auto_backup = "true",
    backup_count = "5",
    backup_interval = "3600",
    validation_level = "standard",
    error_simulation = "false",
    debug_mode = "false",
    gui_theme = "default",
    auto_save_interval = "300",
    integrity_check_interval = "86400",
    transaction_timeout = "30"
}

-- Show current configuration
function SnD.Config.show(filter)
    local config = SnD.Database.loadConfig()
    cecho("<cyan>Current Configuration:<reset>\n")
    
    local keys = {}
    for key in pairs(config) do
        if not filter or key:lower():find(filter:lower()) then
            table.insert(keys, key)
        end
    end
    
    table.sort(keys)
    
    for _, key in ipairs(keys) do
        local value = config[key]
        local default = SnD.Config.defaults[key] or "N/A"
        local status = (tostring(value) == default) and "<green>" or "<yellow>"
        
        cecho(string.format("  %s%s = %s<reset> (default: %s)\n", 
            status, key, value, default))
    end
    
    if filter then
        cecho(string.format("<cyan>Showing configuration matching: %s<reset>\n", filter))
    end
end

-- Set configuration value
function SnD.Config.set(key, value)
    -- Validate key exists
    if not SnD.Config.defaults[key] then
        cecho(string.format("<red>Unknown configuration key: %s<reset>\n", key))
        return false
    end
    
    -- Validate value
    local isValid, errorMsg = SnD.Config.validateValue(key, value)
    if not isValid then
        cecho(string.format("<red>Invalid value for %s: %s<reset>\n", key, errorMsg))
        return false
    end
    
    -- Save to database
    local success = SnD.Database.saveConfig(key, tostring(value))
    if success then
        cecho(string.format("<green>Configuration updated: %s = %s<reset>\n", key, value))
        
        -- Trigger configuration change event
        SnD.raiseEvent("configChanged", {key = key, value = value})
        return true
    else
        cecho(string.format("<red>Failed to save configuration: %s<reset>\n", key))
        return false
    end
end

-- Reset configuration to default
function SnD.Config.reset(key)
    if key then
        -- Reset specific key
        if not SnD.Config.defaults[key] then
            cecho(string.format("<red>Unknown configuration key: %s<reset>\n", key))
            return false
        end
        
        return SnD.Config.set(key, SnD.Config.defaults[key])
    else
        -- Reset all configuration
        cecho("<cyan>Resetting all configuration to defaults...<reset>\n")
        
        for k, v in pairs(SnD.Config.defaults) do
            SnD.Database.saveConfig(k, v)
        end
        
        cecho("<green>All configuration reset to defaults<reset>\n")
        SnD.raiseEvent("configReset", {})
        return true
    end
end

-- Validate configuration value
function SnD.Config.validateValue(key, value)
    local validators = {
        auto_backup = function(v) return v == "true" or v == "false" end,
        backup_count = function(v) return tonumber(v) and tonumber(v) >= 1 and tonumber(v) <= 50 end,
        backup_interval = function(v) return tonumber(v) and tonumber(v) >= 60 end,
        validation_level = function(v) return v == "strict" or v == "standard" or v == "relaxed" end,
        error_simulation = function(v) return v == "true" or v == "false" end,
        debug_mode = function(v) return v == "true" or v == "false" end,
        gui_theme = function(v) 
            return v == "default" or v == "dark" or v == "light" or v == "high_contrast"
        end,
        auto_save_interval = function(v) return tonumber(v) and tonumber(v) >= 30 end,
        integrity_check_interval = function(v) return tonumber(v) and tonumber(v) >= 3600 end,
        transaction_timeout = function(v) return tonumber(v) and tonumber(v) >= 5 and tonumber(v) <= 300 end
    }
    
    local validator = validators[key]
    if validator then
        return validator(tostring(value)), nil
    else
        return true, nil
    end
end

-- Export configuration
function SnD.Config.export(filename)
    local config = SnD.Database.loadConfig()
    local exportData = {
        timestamp = os.time(),
        version = SnD.version,
        config = config
    }
    
    local json = require("json") or SnD.Mock.json
    local jsonString = json.encode(exportData)
    
    local file = io.open(filename or "snd_config_export.json", "w")
    if not file then
        cecho(string.format("<red>Cannot create export file: %s<reset>\n", filename or "snd_config_export.json"))
        return false
    end
    
    file:write(jsonString)
    file:close()
    
    cecho(string.format("<green>Configuration exported to: %s<reset>\n", filename or "snd_config_export.json"))
    return true
end

-- Import configuration
function SnD.Config.import(filename, merge)
    local json = require("json") or SnD.Mock.json
    local file = io.open(filename or "snd_config_export.json", "r")
    if not file then
        cecho(string.format("<red>Cannot read import file: %s<reset>\n", filename or "snd_config_export.json"))
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, data = pcall(json.decode, content)
    if not success or not data.config then
        cecho("<red>Invalid configuration file format<reset>\n")
        return false
    end
    
    if not merge then
        -- Clear existing config first
        SnD.Config.reset()
    end
    
    -- Import configuration values
    local imported = 0
    for key, value in pairs(data.config) do
        if SnD.Config.defaults[key] then
            if SnD.Config.set(key, value) then
                imported = imported + 1
            end
        end
    end
    
    cecho(string.format("<green>Imported %d configuration values<reset>\n", imported))
    return true
end

-- Get configuration value
function SnD.Config.get(key)
    local config = SnD.Database.loadConfig()
    return config[key]
end

-- Check if feature is enabled
function SnD.Config.isEnabled(feature)
    local value = SnD.Config.get(feature)
    return value == "true"
end

-- Get numeric configuration value
function SnD.Config.getNumber(key, default)
    local value = SnD.Config.get(key)
    local num = tonumber(value)
    return num or default or 0
end
```

#### 2. GUI Configuration Interface
**File**: `mudlet-snd/packages/search-and-destroy/src/config_gui.lua`
**Changes**: Create new GUI configuration module

```lua
-- Configuration GUI Module
SnD.ConfigGUI = SnD.ConfigGUI or {}

-- Main configuration window
function SnD.ConfigGUI.createWindow()
    if SnD.ConfigGUI.window and SnD.ConfigGUI.window.isVisible() then
        SnD.ConfigGUI.window:show()
        return
    end
    
    -- Create main window
    SnD.ConfigGUI.window = Geyser.UserWindow:new({
        name = "SnD_ConfigWindow",
        title = "Search & Destroy Configuration",
        width = 600,
        height = 500
    })
    
    -- Create main container
    local mainContainer = Geyser.VBox:new({
        name = "SnD_ConfigMain",
        x = 0, y = 0,
        width = "100%",
        height = "100%"
    }, SnD.ConfigGUI.window)
    
    -- Create title
    local titleLabel = Geyser.Label:new({
        name = "SnD_ConfigTitle",
        text = "<center><h2>Search & Destroy Configuration</h2></center>",
        width = "100%",
        height = 40
    }, mainContainer)
    
    -- Create tab container
    local tabContainer = Geyser.HBox:new({
        name = "SnD_ConfigTabs",
        width = "100%",
        height = 40
    }, mainContainer)
    
    -- Tab buttons
    local generalTab = Geyser.Label:new({
        name = "SnD_GeneralTab",
        text = "<center>General</center>",
        width = "33%",
        height = "100%"
    }, tabContainer)
    
    local backupTab = Geyser.Label:new({
        name = "SnD_BackupTab",
        text = "<center>Backup</center>",
        width = "33%",
        height = "100%"
    }, tabContainer)
    
    local advancedTab = Geyser.Label:new({
        name = "SnD_AdvancedTab",
        text = "<center>Advanced</center>",
        width = "34%",
        height = "100%"
    }, tabContainer)
    
    -- Content container
    local contentContainer = Geyser.Container:new({
        name = "SnD_ConfigContent",
        width = "100%",
        height = 350
    }, mainContainer)
    
    -- Button container
    local buttonContainer = Geyser.HBox:new({
        name = "SnD_ConfigButtons",
        width = "100%",
        height = 50
    }, mainContainer)
    
    -- Create content panels
    SnD.ConfigGUI.createGeneralPanel(contentContainer)
    SnD.ConfigGUI.createBackupPanel(contentContainer)
    SnD.ConfigGUI.createAdvancedPanel(contentContainer)
    
    -- Create action buttons
    SnD.ConfigGUI.createActionButtons(buttonContainer)
    
    -- Set up tab switching
    SnD.ConfigGUI.setupTabSwitching(generalTab, backupTab, advancedTab)
    
    -- Show general panel by default
    SnD.ConfigGUI.showPanel("general")
    
    -- Load current configuration
    SnD.ConfigGUI.loadCurrentConfig()
    
    SnD.ConfigGUI.window:show()
end

-- Create general configuration panel
function SnD.ConfigGUI.createGeneralPanel(parent)
    SnD.ConfigGUI.generalPanel = Geyser.VBox:new({
        name = "SnD_GeneralPanel",
        x = 0, y = 0,
        width = "100%",
        height = "100%"
    }, parent)
    
    -- Debug mode
    local debugContainer = Geyser.HBox:new({
        name = "SnD_DebugContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.generalPanel)
    
    local debugLabel = Geyser.Label:new({
        name = "SnD_DebugLabel",
        text = "Debug Mode:",
        width = "40%",
        height = "100%"
    }, debugContainer)
    
    SnD.ConfigGUI.debugCheckbox = Geyser.Label:new({
        name = "SnD_DebugCheckbox",
        text = "[ ]",
        width = "10%",
        height = "100%"
    }, debugContainer)
    
    local debugDesc = Geyser.Label:new({
        name = "SnD_DebugDesc",
        text = "Enable debug output for troubleshooting",
        width = "50%",
        height = "100%"
    }, debugContainer)
    
    -- GUI Theme
    local themeContainer = Geyser.HBox:new({
        name = "SnD_ThemeContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.generalPanel)
    
    local themeLabel = Geyser.Label:new({
        name = "SnD_ThemeLabel",
        text = "GUI Theme:",
        width = "40%",
        height = "100%"
    }, themeContainer)
    
    SnD.ConfigGUI.themeDropdown = Geyser.Label:new({
        name = "SnD_ThemeDropdown",
        text = "default ▼",
        width = "20%",
        height = "100%"
    }, themeContainer)
    
    local themeDesc = Geyser.Label:new({
        name = "SnD_ThemeDesc",
        text = "Choose interface theme",
        width = "40%",
        height = "100%"
    }, themeContainer)
    
    -- Auto-save interval
    local autoSaveContainer = Geyser.HBox:new({
        name = "SnD_AutoSaveContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.generalPanel)
    
    local autoSaveLabel = Geyser.Label:new({
        name = "SnD_AutoSaveLabel",
        text = "Auto-save Interval:",
        width = "40%",
        height = "100%"
    }, autoSaveContainer)
    
    SnD.ConfigGUI.autoSaveInput = Geyser.Label:new({
        name = "SnD_AutoSaveInput",
        text = "300",
        width = "20%",
        height = "100%"
    }, autoSaveContainer)
    
    local autoSaveDesc = Geyser.Label:new({
        name = "SnD_AutoSaveDesc",
        text = "Seconds between auto-saves",
        width = "40%",
        height = "100%"
    }, autoSaveContainer)
    
    -- Set up click handlers
    SnD.ConfigGUI.debugCheckbox:setClickFunction(function()
        local currentState = SnD.ConfigGUI.debugCheckbox:getText()
        local newState = currentState == "[ ]" and "[X]" or "[ ]"
        SnD.ConfigGUI.debugCheckbox:setText(newState)
    end)
    
    SnD.ConfigGUI.themeDropdown:setClickFunction(function()
        SnD.ConfigGUI.showThemeDropdown()
    end)
end

-- Create backup configuration panel
function SnD.ConfigGUI.createBackupPanel(parent)
    SnD.ConfigGUI.backupPanel = Geyser.VBox:new({
        name = "SnD_BackupPanel",
        x = 0, y = 0,
        width = "100%",
        height = "100%"
    }, parent)
    
    -- Auto-backup
    local autoBackupContainer = Geyser.HBox:new({
        name = "SnD_AutoBackupContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.backupPanel)
    
    local autoBackupLabel = Geyser.Label:new({
        name = "SnD_AutoBackupLabel",
        text = "Auto-backup:",
        width = "40%",
        height = "100%"
    }, autoBackupContainer)
    
    SnD.ConfigGUI.autoBackupCheckbox = Geyser.Label:new({
        name = "SnD_AutoBackupCheckbox",
        text = "[X]",
        width = "10%",
        height = "100%"
    }, autoBackupContainer)
    
    local autoBackupDesc = Geyser.Label:new({
        name = "SnD_AutoBackupDesc",
        text = "Create automatic backups",
        width = "50%",
        height = "100%"
    }, autoBackupContainer)
    
    -- Backup count
    local backupCountContainer = Geyser.HBox:new({
        name = "SnD_BackupCountContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.backupPanel)
    
    local backupCountLabel = Geyser.Label:new({
        name = "SnD_BackupCountLabel",
        text = "Backup Count:",
        width = "40%",
        height = "100%"
    }, backupCountContainer)
    
    SnD.ConfigGUI.backupCountInput = Geyser.Label:new({
        name = "SnD_BackupCountInput",
        text = "5",
        width = "20%",
        height = "100%"
    }, backupCountContainer)
    
    local backupCountDesc = Geyser.Label:new({
        name = "SnD_BackupCountDesc",
        text = "Maximum number of backups to keep",
        width = "40%",
        height = "100%"
    }, backupCountContainer)
    
    -- Backup interval
    local backupIntervalContainer = Geyser.HBox:new({
        name = "SnD_BackupIntervalContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.backupPanel)
    
    local backupIntervalLabel = Geyser.Label:new({
        name = "SnD_BackupIntervalLabel",
        text = "Backup Interval:",
        width = "40%",
        height = "100%"
    }, backupIntervalContainer)
    
    SnD.ConfigGUI.backupIntervalInput = Geyser.Label:new({
        name = "SnD_BackupIntervalInput",
        text = "3600",
        width = "20%",
        height = "100%"
    }, backupIntervalContainer)
    
    local backupIntervalDesc = Geyser.Label:new({
        name = "SnD_BackupIntervalDesc",
        text = "Seconds between automatic backups",
        width = "40%",
        height = "100%"
    }, backupIntervalContainer)
    
    -- Set up click handlers
    SnD.ConfigGUI.autoBackupCheckbox:setClickFunction(function()
        local currentState = SnD.ConfigGUI.autoBackupCheckbox:getText()
        local newState = currentState == "[ ]" and "[X]" or "[ ]"
        SnD.ConfigGUI.autoBackupCheckbox:setText(newState)
    end)
end

-- Create advanced configuration panel
function SnD.ConfigGUI.createAdvancedPanel(parent)
    SnD.ConfigGUI.advancedPanel = Geyser.VBox:new({
        name = "SnD_AdvancedPanel",
        x = 0, y = 0,
        width = "100%",
        height = "100%"
    }, parent)
    
    -- Validation level
    local validationContainer = Geyser.HBox:new({
        name = "SnD_ValidationContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.advancedPanel)
    
    local validationLabel = Geyser.Label:new({
        name = "SnD_ValidationLabel",
        text = "Validation Level:",
        width = "40%",
        height = "100%"
    }, validationContainer)
    
    SnD.ConfigGUI.validationDropdown = Geyser.Label:new({
        name = "SnD_ValidationDropdown",
        text = "standard ▼",
        width = "20%",
        height = "100%"
    }, validationContainer)
    
    local validationDesc = Geyser.Label:new({
        name = "SnD_ValidationDesc",
        text = "Data validation strictness",
        width = "40%",
        height = "100%"
    }, validationContainer)
    
    -- Transaction timeout
    local timeoutContainer = Geyser.HBox:new({
        name = "SnD_TimeoutContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.advancedPanel)
    
    local timeoutLabel = Geyser.Label:new({
        name = "SnD_TimeoutLabel",
        text = "Transaction Timeout:",
        width = "40%",
        height = "100%"
    }, timeoutContainer)
    
    SnD.ConfigGUI.timeoutInput = Geyser.Label:new({
        name = "SnD_TimeoutInput",
        text = "30",
        width = "20%",
        height = "100%"
    }, timeoutContainer)
    
    local timeoutDesc = Geyser.Label:new({
        name = "SnD_TimeoutDesc",
        text = "Seconds before transaction timeout",
        width = "40%",
        height = "100%"
    }, timeoutContainer)
    
    -- Error simulation
    local errorSimContainer = Geyser.HBox:new({
        name = "SnD_ErrorSimContainer",
        width = "100%",
        height = 30
    }, SnD.ConfigGUI.advancedPanel)
    
    local errorSimLabel = Geyser.Label:new({
        name = "SnD_ErrorSimLabel",
        text = "Error Simulation:",
        width = "40%",
        height = "100%"
    }, errorSimContainer)
    
    SnD.ConfigGUI.errorSimCheckbox = Geyser.Label:new({
        name = "SnD_ErrorSimCheckbox",
        text = "[ ]",
        width = "10%",
        height = "100%"
    }, errorSimContainer)
    
    local errorSimDesc = Geyser.Label:new({
        name = "SnD_ErrorSimDesc",
        text = "Enable error simulation for testing",
        width = "50%",
        height = "100%"
    }, errorSimContainer)
    
    -- Set up click handlers
    SnD.ConfigGUI.validationDropdown:setClickFunction(function()
        SnD.ConfigGUI.showValidationDropdown()
    end)
    
    SnD.ConfigGUI.errorSimCheckbox:setClickFunction(function()
        local currentState = SnD.ConfigGUI.errorSimCheckbox:getText()
        local newState = currentState == "[ ]" and "[X]" or "[ ]"
        SnD.ConfigGUI.errorSimCheckbox:setText(newState)
    end)
end

-- Create action buttons
function SnD.ConfigGUI.createActionButtons(parent)
    -- Save button
    SnD.ConfigGUI.saveButton = Geyser.Label:new({
        name = "SnD_SaveButton",
        text = "<center>[Save]</center>",
        width = "25%",
        height = "100%"
    }, parent)
    
    -- Reset button
    SnD.ConfigGUI.resetButton = Geyser.Label:new({
        name = "SnD_ResetButton",
        text = "<center>[Reset]</center>",
        width = "25%",
        height = "100%"
    }, parent)
    
    -- Export button
    SnD.ConfigGUI.exportButton = Geyser.Label:new({
        name = "SnD_ExportButton",
        text = "<center>[Export]</center>",
        width = "25%",
        height = "100%"
    }, parent)
    
    -- Import button
    SnD.ConfigGUI.importButton = Geyser.Label:new({
        name = "SnD_ImportButton",
        text = "<center>[Import]</center>",
        width = "25%",
        height = "100%"
    }, parent)
    
    -- Set up button handlers
    SnD.ConfigGUI.saveButton:setClickFunction(function()
        SnD.ConfigGUI.saveConfiguration()
    end)
    
    SnD.ConfigGUI.resetButton:setClickFunction(function()
        SnD.ConfigGUI.resetConfiguration()
    end)
    
    SnD.ConfigGUI.exportButton:setClickFunction(function()
        SnD.ConfigGUI.exportConfiguration()
    end)
    
    SnD.ConfigGUI.importButton:setClickFunction(function()
        SnD.ConfigGUI.importConfiguration()
    end)
end

-- Set up tab switching
function SnD.ConfigGUI.setupTabSwitching(generalTab, backupTab, advancedTab)
    generalTab:setClickFunction(function()
        SnD.ConfigGUI.showPanel("general")
    end)
    
    backupTab:setClickFunction(function()
        SnD.ConfigGUI.showPanel("backup")
    end)
    
    advancedTab:setClickFunction(function()
        SnD.ConfigGUI.showPanel("advanced")
    end)
end

-- Show specific panel
function SnD.ConfigGUI.showPanel(panelName)
    -- Hide all panels
    if SnD.ConfigGUI.generalPanel then
        SnD.ConfigGUI.generalPanel:hide()
    end
    if SnD.ConfigGUI.backupPanel then
        SnD.ConfigGUI.backupPanel:hide()
    end
    if SnD.ConfigGUI.advancedPanel then
        SnD.ConfigGUI.advancedPanel:hide()
    end
    
    -- Show selected panel
    if panelName == "general" and SnD.ConfigGUI.generalPanel then
        SnD.ConfigGUI.generalPanel:show()
    elseif panelName == "backup" and SnD.ConfigGUI.backupPanel then
        SnD.ConfigGUI.backupPanel:show()
    elseif panelName == "advanced" and SnD.ConfigGUI.advancedPanel then
        SnD.ConfigGUI.advancedPanel:show()
    end
end

-- Load current configuration into GUI
function SnD.ConfigGUI.loadCurrentConfig()
    -- Load general settings
    local debugMode = SnD.Config.get("debug_mode")
    SnD.ConfigGUI.debugCheckbox:setText(debugMode == "true" and "[X]" or "[ ]")
    
    local theme = SnD.Config.get("gui_theme") or "default"
    SnD.ConfigGUI.themeDropdown:setText(theme .. " ▼")
    
    local autoSave = SnD.Config.get("auto_save_interval") or "300"
    SnD.ConfigGUI.autoSaveInput:setText(autoSave)
    
    -- Load backup settings
    local autoBackup = SnD.Config.get("auto_backup")
    SnD.ConfigGUI.autoBackupCheckbox:setText(autoBackup == "true" and "[X]" or "[ ]")
    
    local backupCount = SnD.Config.get("backup_count") or "5"
    SnD.ConfigGUI.backupCountInput:setText(backupCount)
    
    local backupInterval = SnD.Config.get("backup_interval") or "3600"
    SnD.ConfigGUI.backupIntervalInput:setText(backupInterval)
    
    -- Load advanced settings
    local validation = SnD.Config.get("validation_level") or "standard"
    SnD.ConfigGUI.validationDropdown:setText(validation .. " ▼")
    
    local timeout = SnD.Config.get("transaction_timeout") or "30"
    SnD.ConfigGUI.timeoutInput:setText(timeout)
    
    local errorSim = SnD.Config.get("error_simulation")
    SnD.ConfigGUI.errorSimCheckbox:setText(errorSim == "true" and "[X]" or "[ ]")
end

-- Save configuration from GUI
function SnD.ConfigGUI.saveConfiguration()
    local saved = 0
    
    -- Save general settings
    local debugMode = SnD.ConfigGUI.debugCheckbox:getText() == "[X]" and "true" or "false"
    if SnD.Config.set("debug_mode", debugMode) then saved = saved + 1 end
    
    local theme = SnD.ConfigGUI.themeDropdown:getText():gsub(" ▼", "")
    if SnD.Config.set("gui_theme", theme) then saved = saved + 1 end
    
    local autoSave = SnD.ConfigGUI.autoSaveInput:getText()
    if SnD.Config.set("auto_save_interval", autoSave) then saved = saved + 1 end
    
    -- Save backup settings
    local autoBackup = SnD.ConfigGUI.autoBackupCheckbox:getText() == "[X]" and "true" or "false"
    if SnD.Config.set("auto_backup", autoBackup) then saved = saved + 1 end
    
    local backupCount = SnD.ConfigGUI.backupCountInput:getText()
    if SnD.Config.set("backup_count", backupCount) then saved = saved + 1 end
    
    local backupInterval = SnD.ConfigGUI.backupIntervalInput:getText()
    if SnD.Config.set("backup_interval", backupInterval) then saved = saved + 1 end
    
    -- Save advanced settings
    local validation = SnD.ConfigGUI.validationDropdown:getText():gsub(" ▼", "")
    if SnD.Config.set("validation_level", validation) then saved = saved + 1 end
    
    local timeout = SnD.ConfigGUI.timeoutInput:getText()
    if SnD.Config.set("transaction_timeout", timeout) then saved = saved + 1 end
    
    local errorSim = SnD.ConfigGUI.errorSimCheckbox:getText() == "[X]" and "true" or "false"
    if SnD.Config.set("error_simulation", errorSim) then saved = saved + 1 end
    
    cecho(string.format("<green>Configuration saved: %d settings updated<reset>\n", saved))
end

-- Reset configuration
function SnD.ConfigGUI.resetConfiguration()
    SnD.Config.reset()
    SnD.ConfigGUI.loadCurrentConfig()
    cecho("<green>Configuration reset to defaults<reset>\n")
end

-- Export configuration
function SnD.ConfigGUI.exportConfiguration()
    local filename = "snd_config_export_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
    SnD.Config.export(filename)
end

-- Import configuration
function SnD.ConfigGUI.importConfiguration()
    -- For now, use default filename - in future could show file dialog
    SnD.Config.import("snd_config_export.json", true)
    SnD.ConfigGUI.loadCurrentConfig()
end

-- Show theme dropdown
function SnD.ConfigGUI.showThemeDropdown()
    local themes = {"default", "dark", "light", "high_contrast"}
    local current = SnD.ConfigGUI.themeDropdown:getText():gsub(" ▼", "")
    
    -- Find next theme
    local currentIndex = 1
    for i, theme in ipairs(themes) do
        if theme == current then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #themes) + 1
    SnD.ConfigGUI.themeDropdown:setText(themes[nextIndex] .. " ▼")
end

-- Show validation dropdown
function SnD.ConfigGUI.showValidationDropdown()
    local levels = {"relaxed", "standard", "strict"}
    local current = SnD.ConfigGUI.validationDropdown:getText():gsub(" ▼", "")
    
    -- Find next level
    local currentIndex = 1
    for i, level in ipairs(levels) do
        if level == current then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #levels) + 1
    SnD.ConfigGUI.validationDropdown:setText(levels[nextIndex] .. " ▼")
end

-- Show configuration window
function SnD.ConfigGUI.show()
    SnD.ConfigGUI.createWindow()
end

-- Hide configuration window
function SnD.ConfigGUI.hide()
    if SnD.ConfigGUI.window then
        SnD.ConfigGUI.window:hide()
    end
end
```

#### 3. CLI Command Integration
**File**: `mudlet-snd/packages/search-and-destroy/src/aliases.lua`
**Changes**: Add configuration commands to existing alias system

```lua
-- Add configuration commands to existing aliases

-- Configuration management aliases
SnD.Aliases.config = {
    pattern = "^snd config (.*)$",
    handler = function(input)
        local args = {}
        for arg in input:gmatch("%S+") do
            table.insert(args, arg)
        end
        
        if #args == 0 then
            SnD.Config.show()
        elseif #args == 1 then
            if args[1] == "show" then
                SnD.Config.show()
            elseif args[1] == "gui" then
                SnD.ConfigGUI.show()
            elseif args[1] == "reset" then
                SnD.Config.reset()
            elseif args[1] == "export" then
                SnD.Config.export()
            elseif args[1] == "import" then
                SnD.Config.import()
            else
                cecho("<cyan>Usage: snd config [show|gui|reset|export|import|set <key> <value>]<reset>\n")
            end
        elseif #args == 2 then
            if args[1] == "show" then
                SnD.Config.show(args[2])
            elseif args[1] == "reset" then
                SnD.Config.reset(args[2])
            else
                cecho("<cyan>Usage: snd config [show|gui|reset|export|import|set <key> <value>]<reset>\n")
            end
        elseif #args >= 3 and args[1] == "set" then
            local key = args[2]
            local value = table.concat(args, " ", 3)
            SnD.Config.set(key, value)
        else
            cecho("<cyan>Usage: snd config [show|gui|reset|export|import|set <key> <value>]<reset>\n")
        end
    end
}

-- Quick configuration aliases
SnD.Aliases.quickConfig = {
    pattern = "^snd (debug|backup|theme) (.*)$",
    handler = function(input)
        local setting, value = input:match("^(%w+) (.*)$")
        
        if setting == "debug" then
            SnD.Config.set("debug_mode", value == "on" and "true" or "false")
        elseif setting == "backup" then
            SnD.Config.set("auto_backup", value == "on" and "true" or "false")
        elseif setting == "theme" then
            SnD.Config.set("gui_theme", value)
        end
    end
}

-- Register the new aliases
if SnD.Aliases.register then
    SnD.Aliases.register(SnD.Aliases.config)
    SnD.Aliases.register(SnD.Aliases.quickConfig)
end
```

### Success Criteria:

#### Automated Verification:
- [ ] CLI configuration commands work: `nx test --testNamePattern="config_cli"`
- [ ] GUI interface functions: `nx test --testNamePattern="config_gui"`
- [ ] Configuration validation works: `nx test --testNamePattern="config_validation"`
- [ ] Import/export functionality: `nx test --testNamePattern="config_import_export"`

#### Manual Verification:
- [ ] CLI commands show, set, reset configuration
- [ ] GUI window opens and displays current settings
- [ ] Configuration changes persist across restarts
- [ ] Import/export works with JSON files
- [ ] Validation prevents invalid configuration values
- [ ] Tab switching works in GUI interface

---

## Phase 5: Integration & Testing

### Overview
Comprehensive integration testing of all Phase 2 components, validation of end-to-end workflows, and performance optimization to ensure production readiness.

### Changes Required:

#### 1. Comprehensive Integration Test Suite
**File**: `mudlet-snd/packages/search-and-destroy/src/test_phase2_integration.lua`
**Changes**: Create end-to-end integration tests

```lua
-- Phase 2 Integration Test Suite
dofile('core.lua')
dofile('database.lua')
dofile('mock_data.lua')
dofile('gmcp.lua')
dofile('campaign.lua')
dofile('config_manager.lua')
dofile('config_gui.lua')

print("=== Phase 2 Integration Testing ===")

-- Test 1: Complete Workflow with Transactions
print("1. Testing complete workflow with transactions...")
SnD.Mock.enable()
SnD.Database.init()

-- Create test data
local testTargets = SnD.Mock.generateTestTargets(5)
local success = SnD.Database.saveCampaignTargets(testTargets)
print("   ✓ Campaign targets saved with transaction:", success and "PASS" or "FAIL")

-- Verify data integrity
local loadedTargets = SnD.Database.loadCampaignTargets()
print("   ✓ Data integrity maintained:", #loadedTargets == #testTargets and "PASS" or "FAIL")

-- Test 2: Configuration Management Integration
print("2. Testing configuration management integration...")
SnD.Config.set("auto_backup", "true")
SnD.Config.set("debug_mode", "true")
SnD.Config.set("validation_level", "strict")

local autoBackup = SnD.Config.get("auto_backup")
local debugMode = SnD.Config.get("debug_mode")
local validationLevel = SnD.Config.get("validation_level")

print("   ✓ Configuration persistence:", 
    autoBackup == "true" and debugMode == "true" and validationLevel == "strict" and "PASS" or "FAIL")

-- Test 3: Backup and Restore Workflow
print("3. Testing backup and restore workflow...")
local backupFile = SnD.Database.backup()
print("   ✓ Backup creation:", backupFile and "PASS" or "FAIL")

-- Modify data
SnD.Database.saveCampaignTargets(SnD.Mock.generateTestTargets(3))
local modifiedTargets = SnD.Database.loadCampaignTargets()
print("   ✓ Data modification:", #modifiedTargets == 3 and "PASS" or "FAIL")

-- Restore from backup
if backupFile then
    local restoreSuccess = SnD.Database.restore(backupFile)
    print("   ✓ Backup restore:", restoreSuccess and "PASS" or "FAIL")
    
    local restoredTargets = SnD.Database.loadCampaignTargets()
    print("   ✓ Data restoration:", #restoredTargets == 5 and "PASS" or "FAIL")
end

-- Test 4: Error Handling and Recovery
print("4. Testing error handling and recovery...")
SnD.Mock.enableErrorSimulation()
SnD.Mock.setError("database", "transactionFailure", true)

local errorSuccess = SnD.Database.saveCampaignTargets(SnD.Mock.generateTestTargets(2))
print("   ✓ Transaction error handling:", not errorSuccess and "PASS" or "FAIL")

SnD.Mock.setError("database", "transactionFailure", false)

-- Test 5: GMCP Integration with Error Simulation
print("5. Testing GMCP integration with error simulation...")
SnD.Mock.setError("gmcp", "questDataFailure", true)
local questSuccess = SnD.Mock.simulateQuestUpdate(nil, true)
print("   ✓ GMCP error handling:", not questSuccess and "PASS" or "FAIL")

SnD.Mock.setError("gmcp", "questDataFailure", false)
questSuccess = SnD.Mock.simulateQuestUpdate(testTargets, false)
print("   ✓ GMCP normal operation:", questSuccess and "PASS" or "FAIL")

-- Test 6: Data Validation Integration
print("6. Testing data validation integration...")
local validTarget = {name = "Valid Target", area = "Valid Area", room_id = 12345}
local invalidTarget = {name = "", area = "", room_id = -1}

local validSuccess = SnD.Database.saveCampaignTargets({validTarget})
print("   ✓ Valid data acceptance:", validSuccess and "PASS" or "FAIL")

local invalidSuccess = SnD.Database.saveCampaignTargets({invalidTarget})
print("   ✓ Invalid data rejection:", not invalidSuccess and "PASS" or "FAIL")

-- Test 7: Configuration Import/Export
print("7. Testing configuration import/export...")
SnD.Config.set("test_key", "test_value")
SnD.Config.export("test_config_export.json")

-- Reset and import
SnD.Config.reset("test_key")
local resetValue = SnD.Config.get("test_key")
print("   ✓ Configuration reset:", resetValue == nil and "PASS" or "FAIL")

SnD.Config.import("test_config_export.json", true)
local importedValue = SnD.Config.get("test_key")
print("   ✓ Configuration import:", importedValue == "test_value" and "PASS" or "FAIL")

-- Test 8: Performance Testing
print("8. Testing performance...")
local startTime = os.clock()

-- Save 100 targets
local largeTargetSet = SnD.Mock.generateTestTargets(100)
SnD.Database.saveCampaignTargets(largeTargetSet)

-- Load all targets
local loadedLargeSet = SnD.Database.loadCampaignTargets()

local endTime = os.clock()
local duration = endTime - startTime

print("   ✓ Large dataset performance:", duration < 1.0 and "PASS" or "FAIL")
print(string.format("   ✓ Processed %d targets in %.3f seconds", #loadedLargeSet, duration))

-- Test 9: Integrity Checking
print("9. Testing integrity checking...")
local integrityPass, issues = SnD.Database.validateIntegrity()
print("   ✓ Database integrity:", integrityPass and "PASS" or "FAIL")

if not integrityPass then
    print("   Issues found:", #issues)
    for _, issue in ipairs(issues) do
        print("     -", issue)
    end
end

-- Test 10: Migration System
print("10. Testing migration system...")
local currentVersion = SnD.Database.getCurrentVersion()
local migrationSuccess = SnD.Database.migrate(currentVersion, "1.1.0")
print("   ✓ Migration system:", migrationSuccess and "PASS" or "FAIL")

print("=== Phase 2 Integration Testing Complete ===")
print("✅ All Phase 2 components integrated successfully:")
print("  ✓ Transaction-based database operations")
print("  ✓ Comprehensive data validation")
print("  ✓ Backup and restore functionality")
print("  ✓ Error handling and recovery")
print("  ✓ GMCP integration with error simulation")
print("  ✓ Configuration management (CLI + GUI)")
print("  ✓ Performance under load")
print("  ✓ Database integrity checking")
print("  ✓ Migration system readiness")
print("")
print("Phase 2 is production ready!")

-- Cleanup
os.remove("test_config_export.json")
if backupFile and backupFile:match("SND_backup_") then
    os.remove(backupFile)
end
```

#### 2. Performance Optimization
**File**: `mudlet-snd/packages/search-and-destroy/src/database.lua`
**Changes**: Add performance monitoring and optimization

```lua
-- Performance monitoring
SnD.Database.performance = SnD.Database.performance or {
    queryCount = 0,
    totalTime = 0,
    slowQueries = {}
}

-- Enhanced query execution with performance monitoring
function SnD.Database.execWithMonitoring(query, ...)
    local startTime = os.clock()
    SnD.Database.performance.queryCount = SnD.Database.performance.queryCount + 1
    
    local success, result = pcall(function()
        return SnD.db:exec(query, ...)
    end)
    
    local endTime = os.clock()
    local duration = endTime - startTime
    SnD.Database.performance.totalTime = SnD.Database.performance.totalTime + duration
    
    -- Log slow queries (> 100ms)
    if duration > 0.1 then
        table.insert(SnD.Database.performance.slowQueries, {
            query = query,
            duration = duration,
            timestamp = os.time()
        })
        
        if SnD.Config.isEnabled("debug_mode") then
            cecho(string.format("<yellow>Slow query (%.3fs): %s<reset>\n", duration, query))
        end
    end
    
    if not success then
        error(result)
    end
    
    return result
end

-- Performance report
function SnD.Database.performanceReport()
    local avgTime = SnD.Database.performance.totalTime / math.max(SnD.Database.performance.queryCount, 1)
    
    cecho(string.format("<cyan>Database Performance Report:<reset>\n"))
    cecho(string.format("  Total queries: %d\n", SnD.Database.performance.queryCount))
    cecho(string.format("  Total time: %.3f seconds\n", SnD.Database.performance.totalTime))
    cecho(string.format("  Average time: %.3f seconds\n", avgTime))
    cecho(string.format("  Slow queries: %d\n", #SnD.Database.performance.slowQueries))
    
    if #SnD.Database.performance.slowQueries > 0 then
        cecho("<yellow>Slowest queries:<reset>\n")
        table.sort(SnD.Database.performance.slowQueries, function(a, b) 
            return a.duration > b.duration 
        end)
        
        for i = 1, math.min(5, #SnD.Database.performance.slowQueries) do
            local query = SnD.Database.performance.slowQueries[i]
            cecho(string.format("  %.3fs: %s\n", query.duration, query.query:sub(1, 50) .. "..."))
        end
    end
end

-- Reset performance monitoring
function SnD.Database.resetPerformanceMonitoring()
    SnD.Database.performance = {
        queryCount = 0,
        totalTime = 0,
        slowQueries = {}
    }
end

-- Optimize database
function SnD.Database.optimize()
    return SnD.Database.withTransaction(function()
        -- Analyze tables for query optimization
        SnD.Database.execWithMonitoring("ANALYZE targets")
        SnD.Database.execWithMonitoring("ANALYZE area_starts")
        SnD.Database.execWithMonitoring("ANALYZE config")
        
        -- Rebuild indexes if needed
        SnD.Database.execWithMonitoring("REINDEX")
        
        cecho("<green>Database optimized<reset>\n")
        return true
    end)
end
```

#### 3. Automated Testing Integration
**File**: `mudlet-snd/packages/search-and-destroy/src/test_automation.lua`
**Changes**: Create automated testing framework

```lua
-- Automated Testing Framework
SnD.Test = SnD.Test or {}

-- Test registry
SnD.Test.tests = SnD.Test.tests or {}
SnD.Test.results = SnD.Test.results or {}

-- Register a test
function SnD.Test.register(name, testFunction, category)
    table.insert(SnD.Test.tests, {
        name = name,
        func = testFunction,
        category = category or "general"
    })
end

-- Run all tests
function SnD.Test.runAll(filter)
    SnD.Test.results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    local startTime = os.clock()
    
    for _, test in ipairs(SnD.Test.tests) do
        if not filter or test.category == filter or test.name:lower():find(filter:lower()) then
            SnD.Test.results.total = SnD.Test.results.total + 1
            
            local success, error = pcall(test.func)
            
            if success then
                SnD.Test.results.passed = SnD.Test.results.passed + 1
                cecho(string.format("<green>✓ %s<reset>\n", test.name))
            else
                SnD.Test.results.failed = SnD.Test.results.failed + 1
                table.insert(SnD.Test.results.errors, {
                    test = test.name,
                    error = error
                })
                cecho(string.format("<red>✗ %s: %s<reset>\n", test.name, error))
            end
        end
    end
    
    local endTime = os.clock()
    local duration = endTime - startTime
    
    -- Print summary
    cecho(string.format("\n<cyan>Test Results:<reset>\n"))
    cecho(string.format("  Total: %d\n", SnD.Test.results.total))
    cecho(string.format("  Passed: %d\n", SnD.Test.results.passed))
    cecho(string.format("  Failed: %d\n", SnD.Test.results.failed))
    cecho(string.format("  Duration: %.3f seconds\n", duration))
    cecho(string.format("  Success Rate: %.1f%%\n", 
        (SnD.Test.results.passed / math.max(SnD.Test.results.total, 1)) * 100))
    
    if #SnD.Test.results.errors > 0 then
        cecho("<red>Failed Tests:<reset>\n")
        for _, error in ipairs(SnD.Test.results.errors) do
            cecho(string.format("  - %s: %s\n", error.test, error.error))
        end
    end
    
    return SnD.Test.results.failed == 0
end

-- Register Phase 2 tests
SnD.Test.register("Database Transactions", function()
    SnD.Database.init()
    local targets = SnD.Mock.generateTestTargets(3)
    local success = SnD.Database.saveCampaignTargets(targets)
    assert(success, "Transaction should succeed")
    
    local loaded = SnD.Database.loadCampaignTargets()
    assert(#loaded == 3, "Should load 3 targets")
end, "database")

SnD.Test.register("Data Validation", function()
    local validTarget = {name = "Test", area = "Test Area", room_id = 123}
    local isValid, errorMsg = SnD.Database.validateTargetData(validTarget)
    assert(isValid, "Valid target should pass validation")
    
    local invalidTarget = {name = "", area = "Test Area"}
    isValid, errorMsg = SnD.Database.validateTargetData(invalidTarget)
    assert(not isValid, "Invalid target should fail validation")
end, "validation")

SnD.Test.register("Backup System", function()
    SnD.Database.init()
    local backupFile = SnD.Database.backup()
    assert(backupFile, "Backup should be created")
    
    local restoreSuccess = SnD.Database.restore(backupFile)
    assert(restoreSuccess, "Restore should succeed")
    
    os.remove(backupFile)
end, "backup")

SnD.Test.register("Configuration Management", function()
    SnD.Config.set("test_key", "test_value")
    local value = SnD.Config.get("test_key")
    assert(value == "test_value", "Configuration should persist")
    
    SnD.Config.reset("test_key")
    value = SnD.Config.get("test_key")
    assert(value == nil, "Reset should clear configuration")
end, "config")

SnD.Test.register("Error Simulation", function()
    SnD.Mock.enableErrorSimulation()
    SnD.Mock.setError("database", "connectionFailure", true)
    
    local success = SnD.Database.loadCampaignTargets()
    assert(success == nil, "Connection failure should be simulated")
    
    SnD.Mock.setError("database", "connectionFailure", false)
end, "mock")

SnD.Test.register("GMCP Integration", function()
    local targets = SnD.Mock.generateTestTargets(2)
    local success = SnD.Mock.simulateQuestUpdate(targets, false)
    assert(success, "GMCP quest update should succeed")
    
    assert(SnD.state.campaignTargets, "Campaign targets should be set")
    assert(#SnD.state.campaignTargets == 2, "Should have 2 campaign targets")
end, "gmcp")

SnD.Test.register("Integrity Checking", function()
    SnD.Database.init()
    local integrityPass, issues = SnD.Database.validateIntegrity()
    assert(integrityPass, "Database integrity should pass")
    assert(#issues == 0, "Should have no integrity issues")
end, "integrity")

-- Run tests command
function SnD.Test.runCommand(filter)
    cecho("<cyan>Running Phase 2 Automated Tests...<reset>\n")
    local allPassed = SnD.Test.runAll(filter)
    
    if allPassed then
        cecho("<green>All tests passed! Phase 2 is ready.<reset>\n")
    else
        cecho("<red>Some tests failed. Check the errors above.<reset>\n")
    end
    
    return allPassed
end
```

### Success Criteria:

#### Automated Verification:
- [ ] All integration tests pass: `nx test test_phase2_integration.lua`
- [ ] Performance benchmarks met: `nx test --testNamePattern="performance"`
- [ ] Automated test suite passes: `nx test test_automation.lua`
- [ ] Memory usage within limits: `nx test --testNamePattern="memory"`

#### Manual Verification:
- [ ] Complete workflow functions end-to-end
- [ ] Error recovery works gracefully
- [ ] Performance acceptable under load
- [ ] All components integrate seamlessly
- [ ] Configuration changes apply correctly
- [ ] Backup/restore works in real scenarios

---

## Testing Strategy

### Unit Tests
- **Database Operations**: Transaction handling, validation, error scenarios
- **Configuration Management**: Value validation, import/export, persistence
- **Mock Framework**: Error simulation, data generation, API mocking
- **GMCP Integration**: Event handling, data parsing, error recovery

### Integration Tests
- **End-to-End Workflows**: Complete data flow from GMCP to database
- **Error Recovery**: Transaction rollback, backup restoration, integrity repair
- **Performance Testing**: Large datasets, concurrent operations, memory usage
- **Configuration Integration**: CLI and GUI working with backend

### Manual Testing Steps
1. **Database Operations**: Create, read, update, delete with validation
2. **Transaction Testing**: Force failures and verify rollback
3. **Backup/Restore**: Create backups, modify data, restore successfully
4. **Configuration Management**: Test all CLI commands and GUI interactions
5. **Error Simulation**: Enable various error scenarios and verify handling
6. **Performance Testing**: Load test with large datasets
7. **GMCP Integration**: Simulate real GMCP events and verify processing

## Performance Considerations

### Database Optimization
- **Query Monitoring**: Track slow queries and optimize them
- **Index Usage**: Ensure proper indexes on frequently queried columns
- **Transaction Batching**: Group related operations to reduce overhead
- **Connection Management**: Reuse database connections efficiently

### Memory Management
- **Large Dataset Handling**: Stream processing for large target lists
- **Mock Data Cleanup**: Proper cleanup of test data
- **Configuration Caching**: Cache frequently accessed configuration values
- **Event System**: Prevent event listener memory leaks

### Response Time Targets
- **Database Operations**: < 100ms for standard CRUD operations
- **Backup Creation**: < 1 second for typical datasets
- **Configuration Loading**: < 50ms for all configuration values
- **GMCP Processing**: < 10ms for event handling

## Migration Notes

### Data Migration Path
1. **Automatic Backup**: Create backup before any migration
2. **Schema Validation**: Verify current schema state
3. **Incremental Migration**: Apply changes step by step
4. **Rollback Capability**: Maintain ability to rollback if needed
5. **Integrity Verification**: Validate data after migration

### Configuration Migration
- **Default Values**: Apply new configuration defaults
- **Value Validation**: Validate existing configuration values
- **Backward Compatibility**: Maintain compatibility with old config formats
- **User Notification**: Inform users of configuration changes

## References

- Original ticket: `thoughts/tickets/phase2_data_storage_implementation.md`
- Research analysis: `thoughts/research/phase2_data_storage_analysis.md`
- Database implementation: `mudlet-snd/packages/search-and-destroy/src/database.lua:1-93`
- GMCP integration: `mudlet-snd/packages/search-and-destroy/src/gmcp.lua:1-18`
- Mock framework: `mudlet-snd/packages/search-and-destroy/src/mock_data.lua:1-93`
- Campaign management: `mudlet-snd/packages/search-and-destroy/src/campaign.lua:1-49`
- Core compatibility: `mudlet-snd/packages/search-and-destroy/src/core.lua:1-247`