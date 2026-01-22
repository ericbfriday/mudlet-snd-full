# Aardwolf Search and Destroy Migration Workflow Implementation Plan

## Overview

Create a comprehensive migration workflow for porting the Aardwolf Search and Destroy (S&D) plugin from MUSHclient to Mudlet, including evaluation framework, mock data development environment, and systematic implementation through 6 phases. The workflow will result in a functional proof-of-concept demonstrating equivalent S&D functionality through modern Mudlet APIs while maintaining strict Aardwolf automation policy compliance.

## Current State Analysis

### Existing Infrastructure
- **Nx Workspace**: Configured at `/Users/ericfriday/dev/mudlet-snd/mudlet-snd/` with TypeScript/JavaScript support and build toolchain ready
- **Research Documentation**: Comprehensive technical blueprint and analysis documents available
- **Original Source Code**: Multiple S&D variants in `snd-original/` directory for reference
- **Community Solutions**: Existing Mudlet packages (Jieiku/AardwolfMudlet, daagar/damp) provide proven implementation patterns

### Key Discoveries
- **Existing Mudlet Solutions**: Jieiku's AardwolfMudlet already implements runto, room search, and campaign functionality
- **Proven Patterns**: GMCP integration, mapper API usage, and Geyser UI patterns available for adaptation
- **Mapper Integration**: SQLite database patterns and area start room management solutions demonstrated
- **Policy Compliance**: Clear distinction between navigation assistance (legal) and gameplay automation (illegal)

### Technical Architecture Requirements
- **Event-Driven Design**: Use `registerAnonymousEventHandler()` and `raiseEvent()` for decoupled modules
- **GMCP Integration**: Direct access to `gmcp.room.info` and `gmcp.comm.quest` tables
- **Mapper API**: `setAreaUserData()`, `mmp.findRoute()`, `walkTo()` for navigation
- **Geyser UI**: `Geyser.UserWindow`, dynamic labels, and responsive layouts
- **SQLite Persistence**: `db:create()` for structured data storage
- **Namespace Management**: Global `SnD = {}` table to prevent conflicts

## Desired End State

A complete Mudlet package providing:
- **Core S&D Commands**: hunt trick (ht), auto hunt (ah), quick where (qw), awesome kill (ak)
- **Mapper Extender**: xrunto navigation, area start room management, room searching
- **Campaign Management**: Real-time target tracking with GMCP integration
- **Geyser Interface**: Modern, dockable UI with interactive elements
- **Policy Compliance**: Built-in safety mechanisms and combat detection
- **Documentation**: User guides explaining what code does and why for debugging
- **Mock Framework**: Offline development environment with simulated data

## What We're NOT Doing

- Direct translation of MUSHclient XML to Mudlet (architectural incompatibility)
- Automated policy compliance testing (manual verification only)
- Performance benchmarking against original version
- Beta testing phase or distribution planning
- Security analysis (single-user focus)
- Backward compatibility with legacy Mudlet versions

## Implementation Approach

### Phase-Based Development Strategy
Leverage existing community solutions while implementing S&D-specific functionality. Each phase builds working features that can be tested independently before proceeding.

### Evaluation Framework Integration

**Multi-layer Assessment Matrix**:
- **Technical Feasibility (30%)**: API availability, complexity analysis, risk assessment
- **Policy Compliance (40%)**: Automation policy adherence, safety mechanism verification
- **User Experience (20%)**: Interface design, workflow efficiency
- **Maintainability (10%)**: Code quality, documentation clarity

**Validation Stack**:
- Unit Tests: Individual function testing with mock GMCP data
- Integration Tests: Module interaction verification
- Live Tests: In-game functionality validation
- Policy Review: Manual compliance verification

## Phase 1: Core Mapper Logic

### Overview
Implement foundational navigation functionality using proven patterns from existing Mudlet packages.

### Changes Required:

#### 1. Package Structure Setup
**File**: `packages/search-and-destroy/package.json`
**Changes**: Initialize Nx package with Mudlet-specific configuration

```json
{
  "name": "@mudlet-snd/search-and-destroy",
  "version": "1.0.0",
  "scripts": {
    "build": "nx build",
    "test": "nx test",
    "lint": "prettier --check ."
  }
}
```

#### 2. Core Namespace and Event System
**File**: `packages/search-and-destroy/src/core.lua`
**Changes**: Establish global namespace and event framework

```lua
-- Global namespace for Search and Destroy
SnD = SnD or {}
SnD.version = "1.0.0"
SnD.config = SnD.config or {}
SnD.state = SnD.state or {}

-- Event system for decoupled communication
function SnD.raiseEvent(eventName, data)
    raiseEvent("SND." .. eventName, data)
end

function SnD.registerHandler(eventName, handler)
    return registerAnonymousEventHandler("SND." .. eventName, handler)
end
```

#### 3. Area Start Room Management
**File**: `packages/search-and-destroy/src/mapper.lua`
**Changes**: Implement xrunto functionality using `setAreaUserData()` pattern

```lua
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
```

#### 4. Command Aliases
**File**: `packages/search-and-destroy/src/aliases.lua`
**Changes**: Create permanent aliases for mapper commands

```lua
-- snd setstart - Mark current room as area start
permAlias("snd setstart", [[SnD.Mapper.setStartRoom()]])

-- xrunto/xrt - Navigate to area start room  
permAlias("^xrunto (.+)$", [[SnD.Mapper.xrunto(matches[2])]])
permAlias("^xrt (.+)$", [[SnD.Mapper.xrunto(matches[2])]])
```

### Success Criteria:

#### Automated Verification:
- [x] Package builds successfully: `nx build`
- [x] Lua syntax validation passes
- [x] Core mapper functions load without errors
- [x] Area start room persistence works across restarts

#### Manual Verification:
- [x] `snd setstart` successfully marks current room as area start
- [x] `xrunto <area>` navigates to marked start room
- [x] Error messages display for unmapped areas
- [x] Start room data persists after Mudlet restart

---

## Phase 2: Data Parsing & Storage

### Overview
Implement GMCP integration and SQLite database for target and configuration persistence.

### Changes Required:

#### 1. GMCP Event Handlers
**File**: `packages/search-and-destroy/src/gmcp.lua`
**Changes**: Register handlers for room and quest data

```lua
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
```

#### 2. SQLite Database Integration
**File**: `packages/search-and-destroy/src/database.lua`
**Changes**: Create schema and persistence functions

```lua
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
end
```

#### 3. Mock Data Framework
**File**: `packages/search-and-destroy/src/mock_data.lua`
**Changes**: Create simulated GMCP data for offline development

```lua
-- Mock GMCP data generator
SnD.Mock = SnD.Mock or {}

function SnD.Mock.generateRoomInfo(areaName, roomName, roomID)
    return {
        num = roomID or math.random(10000, 99999),
        name = roomName or "Test Room",
        zone = areaName or "Test Area",
        terrain = "city",
        exits = {n = roomID + 1, s = roomID - 1, e = roomID + 2, w = roomID - 2},
        coord = {x = 50, y = 50, cont = 1}
    }
end

function SnD.Mock.generateCampaignTargets()
    return {
        {
            name = "orc warrior",
            area = "Midgaard",
            room_id = 12345,
            vnum = 1201
        },
        {
            name = "city guard",
            area = "New of Darkhaven", 
            room_id = 23456,
            vnum = 2405
        }
    }
end

-- Enable mock mode for development
function SnD.Mock.enable()
    _G.gmcp = _G.gmcp or {}
    _G.gmcp.room = _G.gmcp.room or {}
    _G.gcp.comm = _G.gmcp.comm or {}
    
    -- Override GMCP functions
    function registerAnonymousEventHandler(event, handler)
        if event == "gmcp.room.info" then
            tempTimer(0.1, function()
                handler(nil, SnD.Mock.generateRoomInfo())
            end)
        elseif event == "gmcp.comm.quest" then
            tempTimer(0.1, function()
                handler(nil, {targets = SnD.Mock.generateCampaignTargets()})
            end)
        end
    end
end
```

### Success Criteria:

#### Automated Verification:
- [ ] Database initialization creates all tables: `nx test`
- [ ] GMCP handlers register without errors
- [ ] Mock data generation functions work correctly
- [ ] Data persistence survives profile restarts

#### Manual Verification:
- [ ] Campaign targets automatically save when GMCP data received
- [ ] Mock mode enables offline development
- [ ] Database queries return expected results
- [ ] Configuration changes persist correctly

---

## Phase 3: GUI Development

### Overview
Create modern Geyser-based interface for campaign display and user interaction.

### Changes Required:

#### 1. Main Window Container
**File**: `packages/search-and-destroy/src/gui.lua`
**Changes**: Establish Geyser layout framework

```lua
-- Main GUI container
SnD.GUI = SnD.GUI or {}

function SnD.GUI.init()
    -- Main window (dockable, resizable)
    SnD.GUI.main = Geyser.UserWindow:new({
        name = "SND_Main",
        title = "Search and Destroy",
        x = "70%", y = "30%",
        width = "30%", height = "40%"
    })
    
    -- Vertical layout container
    SnD.GUI.layout = Geyser.VBox:new({
        name = "SND_Layout",
        x = 0, y = 0,
        width = "100%", height = "100%"
    }, SnD.GUI.main)
    
    -- Title label
    SnD.GUI.title = Geyser.Label:new({
        name = "SND_Title",
        text = "<center><b>Search and Destroy</b></center>",
        color = "blue",
        fontSize = 12
    }, SnD.GUI.layout)
    
    -- Campaign list container
    SnD.GUI.campaignContainer = Geyser.Container:new({
        name = "SND_CampaignContainer",
        x = 0, y = 0,
        width = "100%", height = "70%"
    }, SnD.GUI.layout)
    
    -- Button panel
    SnD.GUI.buttonPanel = Geyser.HBox:new({
        name = "SND_ButtonPanel",
        x = 0, y = "70%",
        width = "100%", height = "30%"
    }, SnD.GUI.layout)
end
```

#### 2. Dynamic Campaign Display
**File**: `packages/search-and-destroy/src/campaign_gui.lua`
**Changes**: Implement interactive target list

```lua
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
```

#### 3. Control Buttons
**File**: `packages/search-and-destroy/src/buttons.lua`
**Changes**: Create interactive control panel

```lua
-- Create control buttons
function SnD.GUI.createButtons()
    -- Toggle GUI button
    SnD.GUI.toggleBtn = Geyser.Label:new({
        name = "SND_Toggle",
        text = "[Hide/Show]",
        color = "cyan",
        clickFunction = SnD.GUI.toggle
    }, SnD.GUI.buttonPanel)
    
    -- Update targets button
    SnD.GUI.updateBtn = Geyser.Label:new({
        name = "SND_Update",
        text = "[Update]",
        color = "green", 
        clickFunction = function()
            send("campaign")
        end
    }, SnD.GUI.buttonPanel)
    
    -- Settings button
    SnD.GUI.settingsBtn = Geyser.Label:new({
        name = "SND_Settings",
        text = "[Settings]",
        color = "yellow",
        clickFunction = SnD.GUI.showSettings
    }, SnD.GUI.buttonPanel)
end

-- Toggle GUI visibility
function SnD.GUI.toggle()
    if SnD.GUI.main:isVisible() then
        SnD.GUI.main:hide()
    else
        SnD.GUI.main:show()
    end
end
```

### Success Criteria:

#### Automated Verification:
- [ ] Geyser window creates without errors
- [ ] All GUI components render correctly
- [ ] Event handlers update display properly
- [ ] Click handlers trigger appropriate functions

#### Manual Verification:
- [ ] Campaign targets display in scrollable list
- [ ] Target labels are clickable and navigate correctly
- [ ] Toggle button shows/hides window
- [ ] Window can be resized and docked
- [ ] Tooltips display on hover

---

## Phase 4: Campaign Integration

### Overview
Implement xcp command and real-time campaign workflow integration.

### Changes Required:

#### 1. Campaign Command Processor
**File**: `packages/search-and-destroy/src/campaign.lua`
**Changes**: Implement xcp command with numbered selection

```lua
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
```

#### 2. Real-time Updates
**File**: `packages/search-and-destroy/src/realtime.lua`
**Changes**: Enhance GMCP integration for live updates

```lua
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
```

#### 3. Campaign Alias Integration
**File**: `packages/search-and-destroy/src/aliases.lua` (extension)
**Changes**: Add xcp command alias

```lua
-- Campaign command alias
permAlias("^xcp$", [[SnD.Campaign.process("")]])
permAlias("^xcp (.+)$", [[SnD.Campaign.process(matches[2])]])
```

### Success Criteria:

#### Automated Verification:
- [ ] xcp command processes input correctly
- [ ] Campaign list displays numbered targets
- [ ] Real-time GMCP updates trigger GUI refresh
- [ ] Database saves campaign changes automatically

#### Manual Verification:
- [ ] `xcp` lists all campaign targets with numbers
- [ ] `xcp 3` navigates to third target's area
- [ ] Campaign GUI updates when new targets received
- [ ] Workflow: area navigation → mob search works seamlessly

---

## Phase 5: Advanced Features

### Overview
Implement hunt trick, auto hunt, and safety mechanisms for complete S&D functionality.

### Changes Required:

#### 1. Hunt Trick Implementation
**File**: `packages/search-and-destroy/src/hunt.lua`
**Changes**: Sequential hunting through numbered mob instances

```lua
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
```

#### 2. Auto Hunt Implementation
**File**: `packages/search-and-destroy/src/autohunt.lua`
**Changes**: Automated movement following hunt trails

```lua
-- Auto hunt state
SnD.AutoHunt = SnD.AutoHunt or {
    active = false,
    targetMob = "",
    lastDirection = ""
}

-- Execute auto hunt
function SnD.AutoHunt.execute(mob)
    if not mob then
        mob = SnD.Hunt.lastMob
    end
    
    if not mob then
        cecho("<yellow>No mob specified for auto hunt<reset>")
        return
    end
    
    SnD.AutoHunt.active = true
    SnD.AutoHunt.targetMob = mob
    send("hunt " .. mob)
    
    cecho(string.format("<green>Auto hunt started: %s<reset>", mob))
    SnD.raiseEvent("autoHuntStarted", {mob = mob})
end

-- Process hunt direction output
function SnD.AutoHunt.processDirection(direction)
    if not SnD.AutoHunt.active then return end
    
    SnD.AutoHunt.lastDirection = direction
    
    -- Check for combat before moving
    if gmcp.char.status.state == "combat" then
        SnD.AutoHunt.abort("Combat detected")
        return
    end
    
    -- Send movement command
    send(direction)
    
    cecho(string.format("<cyan>Moving: %s<reset>", direction))
    SnD.raiseEvent("autoHuntMoved", {direction = direction})
end

-- Abort auto hunt
function SnD.AutoHunt.abort(reason)
    if SnD.AutoHunt.active then
        SnD.AutoHunt.active = false
        cecho(string.format("<red>Auto hunt aborted: %s<reset>", reason or "Manual"))
        SnD.raiseEvent("autoHuntAborted", {reason = reason})
    end
end
```

#### 3. Safety Mechanisms
**File**: `packages/search-and-destroy/src/safety.lua`
**Changes**: Policy compliance and combat detection

```lua
-- Combat detection
SnD.registerHandler("combatStatus", function()
    local status = gmcp.char.status.state
    
    if status == "combat" then
        -- Abort all automation
        SnD.Hunt.abort()
        SnD.AutoHunt.abort("Combat detected")
        
        cecho("<red>Combat detected - All automation aborted<reset>")
        SnD.raiseEvent("safetyTriggered", {type = "combat", action = "abort"})
        
    elseif status == "afk" then
        -- Disable all features
        SnD.Hunt.active = false
        SnD.AutoHunt.active = false
        
        cecho("<yellow>AFK detected - Features disabled<reset>")
        SnD.raiseEvent("safetyTriggered", {type = "afk", action = "disable"})
    end
end)

-- Register combat status monitor
registerAnonymousEventHandler("gmcp.char.status", SnD.handlers.combatStatus)

-- Sequence limits
function SnD.Safety.checkSequenceLimit(count)
    local maxLimit = SnD.config.maxHuntSequence or 20
    
    if count > maxLimit then
        SnD.Hunt.abort()
        SnD.AutoHunt.abort("Sequence limit reached")
        cecho(string.format("<red>Safety limit reached: %d hunts<reset>", maxLimit))
        return false
    end
    
    return true
end
```

#### 4. Command Extensions
**File**: `packages/search-and-destroy/src/aliases.lua` (further extension)
**Changes**: Add hunt and auto hunt aliases

```lua
-- Hunt trick aliases
permAlias("^ht (.*)$", [[SnD.Hunt.execute(matches[2])]])
permAlias("^ht$", [[SnD.Hunt.execute()]])
permAlias("^ht abort$", [[SnD.Hunt.abort()]])

-- Auto hunt aliases  
permAlias("^ah (.*)$", [[SnD.AutoHunt.execute(matches[2])]])
permAlias("^ah$", [[SnD.AutoHunt.execute()]])
permAlias("^ah abort$", [[SnD.AutoHunt.abort()]])

-- Awesome kill alias
permAlias("^ak$", [[send("kill " .. (SnD.Hunt.lastMob or "") .. "")]])

-- Quick scan alias
permAlias("^qs$", [[send("scan " .. (SnD.Hunt.lastMob or "") .. "")]])
```

### Success Criteria:

#### Automated Verification:
- [ ] Hunt trick sequences through numbered instances correctly
- [ ] Auto hunt follows directional output properly
- [ ] Combat detection immediately aborts automation
- [ ] All safety mechanisms trigger appropriately
- [ ] Command aliases register and execute functions

#### Manual Verification:
- [ ] `ht citizen` hunts 1.citizen, 2.citizen, etc. until none found
- [ ] `ah orc` sends hunt, then follows movement directions
- [ ] Combat automatically stops both hunt sequences
- [ ] `ak` attacks last hunted mob without requiring full name
- [ ] AFK detection disables all automation features

---

## Phase 6: Polish & Testing

### Overview
Optimize performance, create comprehensive documentation, and finalize proof-of-concept.

### Changes Required:

#### 1. Performance Optimization
**File**: `packages/search-and-destroy/src/performance.lua`
**Changes**: Optimize database queries and UI updates

```lua
-- Database connection pooling
SnD.Performance = SnD.Performance or {
    queryCache = {},
    updateQueue = {}
}

-- Cached area lookups
function SnD.Performance.getAreaID(areaName)
    if SnD.Performance.queryCache[areaName] then
        return SnD.Performance.queryCache[areaName]
    end
    
    local areas = getAreaTable()
    for id, name in pairs(areas) do
        if string.lower(name):find(string.lower(areaName)) then
            SnD.Performance.queryCache[areaName] = id
            return id
        end
    end
    
    return nil
end

-- Batch UI updates
function SnD.Performance.queueGUIUpdate(updateType, data)
    table.insert(SnD.Performance.updateQueue, {
        type = updateType,
        data = data,
        timestamp = getEpoch()
    })
    
    if #SnD.Performance.updateQueue == 1 then
        tempTimer(0.1, SnD.Performance.processUpdateQueue)
    end
end

-- Process queued updates
function SnD.Performance.processUpdateQueue()
    local updates = SnD.Performance.updateQueue
    SnD.Performance.updateQueue = {}
    
    -- Batch similar updates
    local campaignUpdates = {}
    local guiUpdates = {}
    
    for _, update in ipairs(updates) do
        if update.type == "campaign" then
            table.insert(campaignUpdates, update.data)
        else
            table.insert(guiUpdates, update.data)
        end
    end
    
    -- Process updates
    if #campaignUpdates > 0 then
        SnD.GUI.updateCampaigns(campaignUpdates)
    end
    
    if #guiUpdates > 0 then
        SnD.GUI.processBatchUpdates(guiUpdates)
    end
end
```

#### 2. Help System
**File**: `packages/search-and-destroy/src/help.lua`
**Changes**: Comprehensive in-game documentation

```lua
-- Help system
SnD.Help = SnD.Help or {
    topics = {}
}

function SnD.Help.show(topic)
    if not topic then
        SnD.Help.listTopics()
        return
    end
    
    local helpText = SnD.Help.topics[topic]
    if helpText then
        cecho(string.format("<green>%s Help:<reset>\n%s", topic, helpText))
    else
        cecho(string.format("<yellow>No help found for topic: %s<reset>", topic))
    end
end

function SnD.Help.listTopics()
    cecho("<cyan>Search and Destroy Help Topics:<reset>")
    for topic, _ in pairs(SnD.Help.topics) do
        cecho(string.format("  %s", topic))
    end
    cecho("<cyan>Use 'snd help <topic>' for detailed information<reset>")
end

-- Initialize help topics
SnD.Help.topics = {
    ["basic"] = [[
Basic Commands:
  xrunto <area>    - Navigate to area start room
  snd setstart      - Mark current room as area start
  qw <mob>          - Quick where: find mob location
  xcp               - List campaign targets
  xcp <number>       - Navigate to campaign target
]],
    
    ["hunt"] = [[
Hunting Commands:
  ht <mob>          - Hunt trick: sequential hunting
  ht abort           - Stop hunt sequence
  ah <mob>          - Auto hunt: follow hunt trail
  ah abort           - Stop auto hunt
  ak                 - Attack last hunted mob
  qs                 - Scan for last hunted mob
]],
    
    ["policy"] = [[
Policy Compliance:
  All automation stops when:
    - Combat is detected
    - You go AFK
    - Sequence limits are reached
  
  This is NAVIGATION ASSISTANCE only.
  No experience is gained automatically.
]],
    
    ["debug"] = [[
Debugging Commands:
  snd mock           - Enable mock data mode
  snd status          - Show current state
  snd reload          - Reload all modules
  snd clear           - Clear all data
]]
}
```

#### 3. User Documentation
**File**: `packages/search-and-destroy/docs/README.md`
**Changes**: Comprehensive user guide explaining what code does and why

```markdown
# Search and Destroy for Mudlet

## Overview
Search and Destroy (S&D) is a quality-of-life plugin for Aardwolf MUD that provides advanced mob-finding, campaign management, and intelligent navigation capabilities. This Mudlet port maintains the same functionality as the original MUSHclient version while leveraging modern Mudlet APIs for improved performance and maintainability.

## What This Code Does

### Core Navigation
- **Area Start Rooms**: Remembers your preferred entry point for each area using `setAreaUserData()`
- **Smart Pathfinding**: Uses Mudlet's `mmp.findRoute()` and `walkTo()` for efficient navigation
- **Room Searching**: Searches mapper database by room name with partial matching

### Campaign Integration  
- **GMCP Monitoring**: Listens for `gmcp.comm.quest` updates in real-time
- **Target Tracking**: Stores campaign targets in SQLite database for persistence
- **Workflow Integration**: Combines area navigation with mob location finding

### Hunting Features
- **Hunt Trick**: Sequentially hunts numbered instances (1.mob, 2.mob, etc.)
- **Auto Hunt**: Follows hunt trail directions automatically
- **Safety Mechanisms**: Combat detection stops all automation immediately

### Why This Design

### Event-Driven Architecture
The plugin uses Mudlet's event system (`raiseEvent()`, `registerAnonymousEventHandler()`) to decouple components. This means:
- **Better Reliability**: UI updates don't break data parsing
- **Easier Testing**: Each module can be tested independently  
- **Future Extensibility**: Other scripts can listen to S&D events

### Policy Compliance First
All automation includes built-in safety mechanisms:
- **Combat Detection**: Monitors `gmcp.char.status` for combat state
- **AFK Detection**: Disables features when away from keyboard
- **Manual Actions Required**: Every combat action needs user command (`ak`)

### Database Persistence
Using SQLite (`db:create()`) instead of flat files provides:
- **Atomic Operations**: Data corruption resistant
- **Structured Queries**: Efficient searching and sorting
- **Cross-Session Storage**: Settings survive Mudlet restarts

## Installation

1. Download the package to your Mudlet profile directory
2. In Mudlet: Toolbox → Module Manager → Install → select package.xml
3. Restart Mudlet twice (required for module registration)
4. Type `snd help` for available commands

## Configuration

### Basic Setup
```
snd setstart    - Mark current room as area start point
xrunto newbiew  - Test navigation to New Darkhaven
```

### Advanced Settings
Edit configuration in database or use settings GUI (Phase 3+)

## Debugging

### Common Issues
1. **"Area not found"**: Ensure your mapper has the area mapped
2. **"No path found"**: Check for disconnected rooms in mapper
3. **"No start room set"**: Use `snd setstart` in area entrance

### Debug Commands
```
snd mock       - Enable offline development mode
snd status     - Show current internal state
snd reload     - Reload all modules safely
```

## Policy Notes

This plugin provides NAVIGATION ASSISTANCE only and complies with Aardwolf's automation policies:
- ✅ Manual initiation required for all actions
- ✅ Automation stops during combat  
- ✅ No auto-killing or experience gain
- ✅ User must type attack commands

## Development

For developers wanting to extend or modify this plugin:
- All functions are in the `SnD` namespace
- Events use "SND." prefix to avoid conflicts
- Database schema is extensible for new features
- Mock data framework enables offline development
```

#### 4. Final Integration
**File**: `packages/search-and-destroy/src/main.lua`
**Changes**: Module initialization and coordination

```lua
-- Main initialization
function SnD.init()
    -- Initialize core systems
    SnD.Database.init()
    SnD.GUI.init()
    SnD.Mock.enable() -- Remove for production
    
    -- Register all event handlers
    SnD.registerHandler("locationChanged", SnD.GUI.updateLocation)
    SnD.registerHandler("campaignsUpdated", SnD.GUI.updateCampaigns)
    
    -- Load saved data
    SnD.state.campaignTargets = SnD.Database.loadCampaignTargets()
    SnD.state.areaStarts = SnD.Database.loadAreaStarts()
    
    cecho("<green>Search and Destroy v" .. SnD.version .. " loaded<reset>")
    cecho("<cyan>Type 'snd help' for available commands<reset>")
    
    SnD.raiseEvent("initialized", {})
end

-- Register startup
registerAnonymousEventHandler("sysLoadEvent", SnD.init)

-- Cleanup on profile save
registerAnonymousEventHandler("sysExitEvent", function()
    SnD.Database.save()
    SnD.GUI.savePosition()
end)
```

### Success Criteria:

#### Automated Verification:
- [ ] All performance optimizations implemented
- [ ] Help system covers all commands
- [ ] Documentation explains what and why clearly
- [ ] Integration tests pass: `nx test`
- [ ] Build completes without warnings: `nx build`

#### Manual Verification:
- [ ] Help commands provide useful information
- [ ] Documentation explains debugging steps
- [ ] Performance is acceptable with large datasets
- [ ] All features work together seamlessly
- [ ] Package can be installed and uninstalled cleanly

---

## Testing Strategy

### Unit Tests
- Mock GMCP data generation for isolated testing
- Database operation validation with test datasets
- Individual function testing for hunt, mapper, and GUI modules
- Event system verification for proper communication

### Integration Tests  
- Module interaction testing with real mapper data
- GMCP event handling with live Aardwolf connection
- End-to-end workflow testing (campaign → navigation → hunt)
- Performance testing with large area databases

### Manual Testing Steps
1. **Setup**: Install package in clean Mudlet profile
2. **Basic Navigation**: Test xrunto and snd setstart commands
3. **Campaign Integration**: Verify xcp command works with active campaigns
4. **Hunting Features**: Test ht and ah sequences with various mobs
5. **Safety Verification**: Confirm combat detection stops automation
6. **Performance**: Test with large areas and many targets
7. **Documentation Review**: Validate help commands and README clarity

## Performance Considerations

- **Database Queries**: Use indexing and caching for frequent lookups
- **GUI Updates**: Batch updates to prevent flickering
- **Event Processing**: Debounce rapid GMCP updates
- **Memory Management**: Clear old data and unused references
- **Pathfinding**: Cache area-to-area routes when possible

## Migration Notes

### From Existing Solutions
- **Jieiku's runto**: Adapt area navigation logic
- **daagar's dmap**: Use database integration patterns
- **Community Standards**: Follow established GMCP handling

### For New Developers
- Event-driven architecture enables independent module development
- Clear separation between data parsing, storage, and display
- Mock framework supports offline development and testing
- Comprehensive documentation explains design decisions

## References

- Original ticket: `thoughts/tickets/feature_migration_workflow.md`
- Research documents: `thoughts/research/2025-11-18_migration_workflow_research.md`
- Technical blueprint: `Porting Aardwolf Search and Destroy.md`
- Implementation analysis: `Search_and_Destroy_Mudlet_Port_Analysis.md`
- Community solutions: https://github.com/Jieiku/AardwolfMudlet, https://github.com/daagar/damp
- Original source: `snd-original/` directory with multiple S&D variants