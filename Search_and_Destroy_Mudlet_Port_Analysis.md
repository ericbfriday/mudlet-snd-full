# Search and Destroy for Aardwolf: Mudlet Port Analysis and PRD Foundation

## Executive Summary

Search and Destroy (S&D) is a quality-of-life navigation plugin for Aardwolf MUD that has become one of the most popular tools in the MUSHclient ecosystem. Originally created by WinkleWinkle, enhanced by Starling, and currently maintained by Crowley, it provides advanced mob-finding, campaign management, and intelligent speedwalking capabilities. This document provides comprehensive technical analysis for porting S&D to Mudlet while ensuring policy compliance and alignment with modern Mudlet standards.

**Critical Policy Context**: S&D walks a fine line with Aardwolf's automation policies. It is explicitly **legal** as designed, but can easily become illegal if modified to auto-kill mobs or complete tasks without manual intervention. Any Mudlet port must maintain this careful balance.

---

## 1. Core Functionality Overview

### 1.1 Hunt Trick (ht)
**Purpose**: Automated sequential hunting through numbered mob instances  
**Usage**:
- `ht citizen` - Hunts all citizens starting from 1.citizen upward
- `ht 3 citizen` - Starts hunting from 3.citizen
- `ht abort` - Stops current hunt sequence
- `ht` - Repeats last hunt
- `ht find` - Confirms if last hunted mob is in current room

**Technical Implementation**: 
- Sends hunt commands sequentially (hunt 1.mob, hunt 2.mob, etc.)
- Parses hunt responses to determine if mob exists
- Continues until no more instances found or user aborts
- Stores last mob keyword for quick repeat

### 1.2 Auto Hunt (ah)
**Purpose**: Automated movement toward a mob using hunt tracking  
**Usage**:
- `ah citizen` - Auto-hunts and follows hunt trail to mob
- `ah 3.citizen` - Auto-hunts specific instance
- `ah abort` - Stops auto-hunt sequence
- `ah` - Repeats last auto-hunt

**Technical Implementation**:
- Sends "hunt <mob>" command
- Parses directional output from hunt skill
- Automatically sends movement commands following trail
- Stops on: mob found, combat initiated, or manual abort
- Critical: Does NOT attack automatically (policy compliance)

### 1.3 Quick Where (qw)
**Purpose**: Location finding with clickable speedwalk links  
**Usage**:
- `qw lich` - Returns room name and speedwalk hyperlink to lich location
- `qw` - Repeats last where search

**Technical Implementation**:
- Sends "where <mob>" command
- Parses output for room names and vnums
- Queries mapper database for room information
- Generates clickable hyperlinks to matching rooms
- May return multiple results (mob in multiple rooms)
- Uses GMCP room.info data for vnum correlation

### 1.4 Awesome Kill (ak)
**Purpose**: Attack last searched mob without typos  
**Usage**:
- `ak` - Kills the last mob from ht/qw commands

**Technical Implementation**:
- Stores last mob keyword from ht/qw
- Sends customizable kill command (default: "kill <mob>")
- Can be overridden by creating alias for "k *" pattern
- **Critical**: Requires manual execution (no auto-trigger on room entry)

### 1.5 Quick Scan (qs)
**Purpose**: Scan for last searched mob  
**Usage**:
- `qs` - Scans for last mob from ht/qw

**Technical Implementation**:
- Retrieves last mob keyword
- Sends "scan <mob>" command

### 1.6 Mapper Extender Features

#### Area Navigation
**Commands**:
- `xrunto <areaname>` or `xrt <areaname>` - Runs to first room discovered in area
- `xset mark` - Marks current room as area's "start" room
- `xset speed` - Toggles walk/run for movement
- `xmapper move <roomid>` - Uses set movement speed
- `xmapper move <walk|run> <roomid>` - Temporary movement speed

#### Room Searching
**Commands**:
- `xm <roomname>` - Lists exact then partial matches in current area
- `xmall <roomname>` - Searches all areas (use cautiously)
- `go <index>` - Runs to numbered room from search results
- `go` - Goes to first result (equivalent to `go 1`)
- `nx` - Goes to next numbered room in sequence

#### Campaign Management (xcp)
**Purpose**: Streamlines campaign completion workflow  
**Commands**:
- `xcp` - Lists all active campaign mobs with numbering
- `xcp <index>` - For area campaigns: runs to area and does qw for mob
- `xcp <index>` - For room campaigns: lists matching rooms

**Technical Implementation**:
- Parses campaign data from GMCP or text output
- Identifies campaign type (area-based vs room-based)
- For area campaigns: extracts area name, uses xrt to navigate, calls qw
- For room campaigns: searches mapper DB for exact room name matches
- Presents numbered list for easy selection

#### Utility Commands
**Commands**:
- `roomnote` - Lists mapper notes for current room
- `roomnote area` - Lists all mapper notes in current area (useful for mazes)
- `xset pk` - Toggles PK flag display in searches
- `xset vidblain` - Toggles speedwalk hack for vidblain areas without portals
- `xset reset gui` - Resets Extender GUI position

---

## 2. Technical Architecture (MUSHclient Implementation)

### 2.1 Plugin Dependencies

#### GMCP Handler Plugin
**Plugin ID**: `3e7dedbe37e44942dd46d264`  
**Purpose**: Core GMCP protocol implementation  
**Key Functions**:
- Receives GMCP messages from Aardwolf server
- Stores data in serialized Lua tables
- Broadcasts updates via `OnPluginBroadcast()`
- Provides `CallPlugin("gmcpval", namespace)` interface

**Critical GMCP Namespaces Used**:
```lua
-- Character vitals and status
gmcp.char.vitals    -- hp, mana, moves
gmcp.char.stats     -- level, str, dex, etc.
gmcp.char.status    -- state, enemy, afk

-- Room information (ESSENTIAL for S&D)
gmcp.room.info      -- {
    num: 12345,           -- Room vnum
    name: "Room Name",
    zone: "Area Name",
    terrain: "city",
    exits: {
        n: 12346,         -- Exit destinations
        e: 12347,
        s: 12344
    },
    coord: {x: 50, y: 25, cont: 1}
}

-- Campaign tracking
gmcp.comm.quest     -- Quest status and targets
```

#### GMCP Mapper Plugin
**Plugin ID**: `b6eae87ccedd84f510b74714`  
**Purpose**: SQLite-based world mapper using GMCP room data  
**Database**: `Aardwolf.db` (SQLite3)  
**Key Functions**:
- `CallPlugin("mapper_find_query", query)` - Search rooms by name
- `CallPlugin("mapper_goto", roomid)` - Generate speedwalk to room
- `CallPlugin("mapper_where", roomid)` - Get directions to room

**Database Schema** (relevant tables):
```sql
-- Rooms table
CREATE TABLE rooms (
    uid INTEGER PRIMARY KEY,
    name TEXT,
    area TEXT,
    terrain TEXT,
    info TEXT,  -- Serialized exit data
    x INTEGER,
    y INTEGER,
    z INTEGER,
    continent INTEGER
);

-- Exits table (stores all connections)
CREATE TABLE exits (
    uid INTEGER,
    dir TEXT,
    dest INTEGER,
    FOREIGN KEY (uid) REFERENCES rooms(uid)
);

-- Areas table
CREATE TABLE areas (
    uid INTEGER PRIMARY KEY,
    name TEXT,
    start_room INTEGER  -- User-set via xset mark
);

-- Notes table (mapper annotations)
CREATE TABLE notes (
    roomid INTEGER,
    note TEXT,
    FOREIGN KEY (roomid) REFERENCES rooms(uid)
);
```

### 2.2 Core Plugin Architecture

**Plugin Structure** (Search_and_Destroy.xml):
```xml
<plugin
   name="Search_and_Destroy"
   author="WinkleWinkle, Starling, Crowley"
   id="unique-plugin-id"
   language="Lua"
   purpose="Find mobs faster"
   requires="4.76"
   save_state="y">
   
   <!-- Aliases for user commands -->
   <aliases>
      <alias script="hunt_trick" match="^ht\s*(.*)$" enabled="y" regexp="y"/>
      <alias script="auto_hunt" match="^ah\s*(.*)$" enabled="y" regexp="y"/>
      <alias script="quick_where" match="^qw\s*(.*)$" enabled="y" regexp="y"/>
      <!-- ... more aliases -->
   </aliases>
   
   <!-- Triggers for parsing MUD output -->
   <triggers>
      <trigger match="You are already hunting" script="hunt_already"/>
      <trigger match="You cannot hunt that" script="hunt_not_found"/>
      <trigger match="^(.+) is (here|close)" script="hunt_success"/>
      <!-- ... more triggers -->
   </triggers>
   
   <!-- Scripts -->
   <script>
   <![CDATA[
      -- Lua implementation
   ]]>
   </script>
</plugin>
```

**Key Data Structures**:
```lua
-- State management
local last_mob = ""           -- Last searched mob keyword
local hunt_sequence = {       -- Active hunt trick state
    base_mob = "",
    current_index = 1,
    active = false
}

local auto_hunt_state = {     -- Auto hunt tracking
    active = false,
    mob = "",
    last_direction = ""
}

local search_results = {}     -- xm/xmall search results
local campaign_list = {}      -- Parsed campaign data

-- Area management
local area_start_rooms = {}   -- User-defined area entry points
```

### 2.3 Integration Points

**GMCP Broadcast Handling**:
```lua
function OnPluginBroadcast(msg, id, name, text)
    if id == '3e7dedbe37e44942dd46d264' then  -- GMCP Handler
        if text == "comm.quest" then
            -- Update campaign list
            res, gmcparg = CallPlugin(id, "gmcpval", "comm.quest")
            luastmt = "gmcpdata = " .. gmcparg
            assert(loadstring(luastmt or ""))()
            parse_campaign_data(gmcpdata)
        end
        
        if text == "room.info" then
            -- Update current room for auto-hunt
            res, gmcparg = CallPlugin(id, "gmcpval", "room.info")
            luastmt = "gmcpdata = " .. gmcparg
            assert(loadstring(luastmt or ""))()
            current_room = gmcpdata
        end
    end
end
```

**Mapper Integration**:
```lua
function find_room_by_name(room_name)
    -- Query mapper database
    local results = CallPlugin(
        "b6eae87ccedd84f510b74714", 
        "map_find_query", 
        room_name
    )
    return parse_room_results(results)
end

function speedwalk_to_room(room_id)
    return CallPlugin(
        "b6eae87ccedd84f510b74714",
        "mapper_goto",
        room_id
    )
end
```

---

## 3. Aardwolf Automation Policy Compliance

### 3.1 Legal Features (As Designed)
✅ **Hunt Trick**: Automated sequential hunting is legal - player must manually decide when to hunt and which mobs  
✅ **Auto Hunt**: Following hunt trails is legal - player initiates each hunt  
✅ **Quick Where**: Information gathering is legal  
✅ **Awesome Kill**: Manual kill command is legal - requires player to type `ak`  
✅ **Mapper Navigation**: Speedwalking is legal  
✅ **Campaign Management**: Displaying campaign info is legal  

### 3.2 Illegal Modifications (DO NOT IMPLEMENT)
❌ **Auto-Kill on Room Entry**: Triggers that attack mobs when entering a room  
❌ **Auto-Campaign Completion**: Automatic sequence of: navigate → hunt → kill → return → repeat  
❌ **AFK Operation**: Any feature that gains experience while player is AFK  
❌ **Stacked Kill Commands**: Commands that clear entire areas without player interaction  

### 3.3 Enforcement Test
> "If I had to leave suddenly, would my triggers continue gaining me something?"

**S&D Answer**: NO - All features require explicit player commands for each action. The plugin provides **decision support and navigation assistance**, not automated gameplay.

### 3.4 Critical Design Principle
```
NAVIGATION ASSISTANCE ✅  |  GAMEPLAY AUTOMATION ❌
─────────────────────────┼──────────────────────────
"Go to this mob"         │  "Kill this mob"
"Here's where it is"     │  "Complete this campaign"
"Follow this trail"      │  "Repeat until done"
```

---

## 4. Mudlet Port Requirements

### 4.1 Core Mudlet APIs Needed

#### GMCP Event System
```lua
-- Mudlet native GMCP handling
registerAnonymousEventHandler("gmcp.room.info", function(_, data)
    -- Room data automatically in gmcp.room.info table
    current_room = gmcp.room.info
    update_auto_hunt()
end)

registerAnonymousEventHandler("gmcp.comm.quest", function(_, data)
    -- Campaign data in gmcp.comm.quest table
    parse_campaign_data(gmcp.comm.quest)
end)
```

**Key Differences from MUSHclient**:
- Mudlet automatically parses GMCP JSON into Lua tables
- No need for `CallPlugin()` - data is directly accessible
- Event handlers use `registerAnonymousEventHandler()` instead of `OnPluginBroadcast()`
- GMCP namespaces follow dot notation: `gmcp.char.vitals.hp`

#### Mapper API
```lua
-- Mudlet's mapper functions
getAreaRooms(areaID)           -- Get all rooms in area
searchRoom(roomName, exact)    -- Search for rooms by name
getRoomIDbyHash(hash)          -- Get room by unique hash
getRoomName(roomID)            -- Get room name
getPath(fromID, toID)          -- Calculate shortest path
speedWalk(path, backwards)     -- Execute speedwalk

-- Room information
getRoomExits(roomID)           -- Get exit table
getRoomArea(roomID)            -- Get area ID
getRoomCoordinates(roomID)     -- Get x, y, z coords

-- Custom room data (for area start rooms)
setRoomUserData(roomID, key, value)
getRoomUserData(roomID, key)

-- Room notes
setRoomChar(roomID, character)
getRoomChar(roomID)
```

#### Database Integration
```lua
-- Mudlet mapper uses internal SQLite, but can query:
db:open("/path/to/map.dat")
-- Map structure is different from MUSHclient's

-- For custom data (area start rooms, etc.):
-- Use Mudlet's persistent table storage
local area_starts = area_starts or {}
area_starts["Dark Forest"] = 12345
```

### 4.2 UI Components Needed

#### Command Window (xcp display)
```lua
-- Create GUI window for campaign list
campaign_window = Geyser.MiniConsole:new({
    name = "campaign_window",
    x = 0, y = 0,
    width = 400, height = 300,
    fontSize = 10
})

-- Display numbered campaign list with clickable links
function display_campaigns()
    campaign_window:clear()
    for i, mob in ipairs(campaign_mobs) do
        campaign_window:echo(string.format(
            '<a href="command:xcp %d">%d. %s (%s)</a>\n',
            i, i, mob.name, mob.area
        ))
    end
end
```

#### Mapper Extender GUI
- Room search results display
- Area navigation controls
- Settings panel for toggles (pk flag, speed mode, etc.)

### 4.3 State Management

**Mudlet Persistent Storage**:
```lua
-- Use module tables (saved automatically)
SnD = SnD or {
    settings = {
        movement_speed = "run",  -- walk or run
        show_pk = false,
        vidblain_hack = false
    },
    state = {
        last_mob = "",
        hunt_sequence = nil,
        auto_hunt_active = false,
        search_results = {},
        area_start_rooms = {}
    }
}

-- Saved in profile between sessions
```

### 4.4 Trigger and Alias System

**Mudlet Pattern Matching**:
```lua
-- Aliases (use Perl regex)
"^ht\\s*(.*)$"    -- Hunt trick
"^ah\\s*(.*)$"    -- Auto hunt
"^qw\\s*(.*)$"    -- Quick where
"^xrt\\s+(.+)$"   -- Run to area

-- Triggers (for hunt parsing)
"^You cannot hunt that\\."
"^You are already hunting (.+)\\."
"^(.+) is (here|close by)"
"^In the room (\\d+) rooms? to the (\\w+)"

-- Color triggers for ANSI output parsing
-- (Aardwolf uses color codes extensively)
```

### 4.5 Command Queueing

**Critical for Auto-Hunt**:
```lua
-- Mudlet has sendAll() but need smarter queue
local command_queue = {}

function queue_command(cmd, delay)
    table.insert(command_queue, {
        command = cmd,
        delay = delay or 0
    })
end

function process_queue()
    if #command_queue == 0 then return end
    
    local cmd = table.remove(command_queue, 1)
    send(cmd.command)
    
    if cmd.delay > 0 then
        tempTimer(cmd.delay, [[process_queue()]])
    else
        process_queue()
    end
end
```

---

## 5. Migration Challenges

### 5.1 Mapper Database Differences

**MUSHclient Mapper**:
- SQLite database with fixed schema
- Direct SQL queries
- Plugin-to-plugin communication via `CallPlugin()`
- Room data stored in specific tables

**Mudlet Mapper**:
- Internal binary format (.dat file)
- Lua API access only (no direct SQL)
- Event-based updates
- Different room ID allocation
- Area management more structured

**Solution**: Create abstraction layer
```lua
local MapperAPI = {
    searchRooms = function(query, area_id)
        -- Implement search logic using Mudlet APIs
        local results = {}
        local rooms = area_id and getAreaRooms(area_id) or getRooms()
        for id, room in pairs(rooms) do
            if string.find(string.lower(getRoomName(id)), 
                          string.lower(query)) then
                table.insert(results, {
                    id = id,
                    name = getRoomName(id),
                    area = getRoomAreaName(getRoomArea(id))
                })
            end
        end
        return results
    end,
    
    speedwalkToRoom = function(target_id)
        local current = getRoomID()
        local path = getPath(current, target_id)
        if path and #path > 0 then
            speedWalk(path)
            return true
        end
        return false
    end
}
```

### 5.2 GMCP Data Access

**MUSHclient**: Requires plugin interaction and string deserialization
```lua
res, gmcparg = CallPlugin(id, "gmcpval", "room.info")
luastmt = "gmcpdata = " .. gmcparg
assert(loadstring(luastmt or ""))()
```

**Mudlet**: Direct table access
```lua
local room_vnum = gmcp.room.info.num
local room_name = gmcp.room.info.name
```

**Impact**: Mudlet version will be cleaner and more efficient

### 5.3 String Parsing vs Structured Data

**Aardwolf Output Parsing**:
- Hunt command output: Text-based direction parsing
- Where command output: Text-based room name extraction
- Campaign info: May use both GMCP and text parsing

**Implementation Note**: 
- Prioritize GMCP data where available
- Fall back to text parsing for legacy support
- Use regex patterns carefully (ANSI codes can interfere)

**ANSI Stripping**:
```lua
function strip_ansi(str)
    -- Remove ANSI color codes
    return string.gsub(str, "\27%[%d+;?%d*;?%d*m", "")
end
```

### 5.4 Window Management

**MUSHclient**: Uses miniwindows with absolute positioning
**Mudlet**: Uses Geyser framework with relative positioning

```lua
-- Mudlet Geyser layout
local SnD_GUI = Geyser.Container:new({
    name = "SnD_GUI",
    x = "70%", y = "70%",
    width = "30%", height = "30%"
})

local campaign_list = Geyser.MiniConsole:new({
    name = "campaign_list",
    x = 0, y = 0,
    width = "100%", height = "80%"
}, SnD_GUI)

local button_panel = Geyser.HBox:new({
    name = "button_panel",
    x = 0, y = "80%",
    width = "100%", height = "20%"
}, SnD_GUI)
```

---

## 6. Implementation Roadmap

### Phase 1: Core Functionality (MVP)
**Goal**: Basic mob finding and navigation  
**Timeline**: 2-3 weeks

**Components**:
1. GMCP room.info event handling
2. Last mob storage system
3. Basic aliases:
   - `ht <mob>` - Single hunt (no sequencing yet)
   - `qw <mob>` - Quick where with text output (no GUI)
   - `ak` - Awesome kill
4. Hunt response parsing (success/failure detection)
5. Where response parsing (room name extraction)
6. Basic mapper integration (getPath, speedWalk)

**Deliverable**: Working ht/qw/ak commands with console output

### Phase 2: Sequential Hunting & Auto-Hunt
**Goal**: Advanced mob finding automation  
**Timeline**: 2 weeks

**Components**:
1. Hunt Trick sequencing logic
   - Track current index in sequence
   - Increment on "cannot hunt that"
   - Stop on successful hunt or user abort
2. Auto Hunt implementation
   - Direction parsing from hunt output
   - Automated movement
   - Combat detection (stop condition)
3. Command queueing system
4. Abort mechanism (`ht abort`, `ah abort`)

**Deliverable**: Full ht/ah functionality matching MUSHclient version

### Phase 3: Mapper Extender Core
**Goal**: Area navigation and room searching  
**Timeline**: 2-3 weeks

**Components**:
1. Area start room management
   - `xset mark` command
   - Persistent storage
   - `xrunto`/`xrt` implementation
2. Room searching
   - `xm <roomname>` - Current area search
   - `xmall <roomname>` - Global search
   - Result numbering system
3. Navigation by index
   - `go <index>` - Go to search result
   - `nx` - Next result
4. Movement speed control
   - `xset speed` toggle
   - Walk vs run mode

**Deliverable**: Full mapper extender search and navigation

### Phase 4: Campaign Integration
**Goal**: Campaign workflow streamlining  
**Timeline**: 2 weeks

**Components**:
1. GMCP comm.quest parsing
2. Campaign type detection (area vs room)
3. `xcp` list display
4. `xcp <index>` routing
   - Area campaigns: xrt + qw sequence
   - Room campaigns: room matching
5. Campaign GUI window (optional)

**Deliverable**: Full campaign management system

### Phase 5: Advanced Features & Polish
**Goal**: Feature parity and UX enhancements  
**Timeline**: 2-3 weeks

**Components**:
1. GUI implementation
   - Campaign window
   - Search results window
   - Settings panel
2. Additional features
   - `roomnote` / `roomnote area`
   - PK flag toggle
   - Vidblain hack
3. Help system
   - `xhelp` command
   - Context-sensitive help
4. Update mechanism (if applicable)
5. Documentation
6. Testing and bug fixes

**Deliverable**: Production-ready plugin

### Phase 6: Community Testing & Iteration
**Goal**: Stability and user feedback  
**Timeline**: Ongoing

**Process**:
1. Alpha release to limited testers
2. Bug tracking and prioritization
3. Performance optimization
4. Feature requests evaluation
5. Beta release
6. Public release

---

## 7. Technical Specifications for PRD

### 7.1 System Requirements

**Minimum**:
- Mudlet 4.10+ (GMCP support)
- Aardwolf MUD account
- Active mapper database (some rooms mapped)

**Recommended**:
- Mudlet 4.17+ (latest stable)
- Lua 5.1 compatibility
- 100MB+ mapped areas
- GMCP enabled on Aardwolf account

### 7.2 Performance Targets

**Response Times**:
- Command execution: < 100ms
- Room search (current area): < 500ms
- Room search (all areas): < 2s for 10k+ rooms
- Speedwalk generation: < 200ms
- GUI rendering: < 100ms

**Memory Usage**:
- Base plugin: < 5MB RAM
- With GUI: < 10MB RAM
- Database cache: < 20MB RAM

**CPU Usage**:
- Idle: < 1% CPU
- Active search: < 10% CPU spike
- Sustained navigation: < 5% CPU

### 7.3 Error Handling

**Critical Errors**:
- Mapper database unavailable → Graceful degradation, show error message
- GMCP disconnection → Queue commands, retry on reconnect
- Invalid room ID → Show user-friendly error, suggest using xm search

**Non-Critical**:
- Mob not found → Continue next in sequence or inform user
- Area not found → Suggest close matches
- Invalid command syntax → Display help

**Logging**:
```lua
SnD.log_level = "info"  -- debug, info, warn, error

function SnD.log(level, message)
    if log_levels[level] >= log_levels[SnD.log_level] then
        cecho(string.format("<dim_grey>[SnD:%s]<reset> %s\n", 
                           level, message))
    end
end
```

### 7.4 Configuration Schema

```lua
SnD.config = {
    -- Movement settings
    movement = {
        default_speed = "run",        -- "walk" or "run"
        use_portals = true,
        use_cexits = true,
        delay_between_moves = 0       -- milliseconds
    },
    
    -- Display settings
    display = {
        show_pk_rooms = false,
        color_scheme = "default",     -- "default", "dark", "light"
        gui_position = {x = "70%", y = "70%"},
        gui_size = {width = "30%", height = "30%"},
        font_size = 10
    },
    
    -- Hunt settings
    hunt = {
        max_sequential_hunts = 20,    -- Safety limit
        auto_hunt_delay = 0.5,        -- Seconds between moves
        abort_on_combat = true,
        abort_on_aggressive = true
    },
    
    -- Campaign settings
    campaign = {
        auto_update = true,           -- Update on GMCP changes
        highlight_current = true,
        group_by_area = true
    },
    
    -- Search settings
    search = {
        max_results = 50,
        current_area_first = true,
        fuzzy_matching = true,
        case_sensitive = false
    },
    
    -- Advanced
    advanced = {
        vidblain_hack = false,
        debug_mode = false,
        backup_commands = true,       -- Store command history
        telnet_102_integration = false -- Future feature
    }
}
```

### 7.5 Command Reference

**Hunt Commands**:
```
ht [<number>.]<mob>     Hunt trick - sequential hunting
ht                      Repeat last hunt
ht abort                Stop hunt sequence
ht find                 Check if last mob is here

ah [<number>.]<mob>     Auto-hunt to mob location
ah                      Repeat last auto-hunt  
ah abort                Stop auto-hunt

qw <mob>                Quick where - find mob location
qw                      Repeat last where

ak                      Awesome kill - attack last mob
qs                      Quick scan - scan for last mob
```

**Mapper Commands**:
```
xrunto <area>           Run to area start room
xrt <area>              Alias for xrunto

xm <roomname>           Search rooms in current area
xmall <roomname>        Search all areas
go [<index>]            Go to search result (default: 1)
nx                      Go to next result

xmapper move <roomid>   Move to room with set speed
xmapper move <walk|run> <roomid>  Move with specific speed
```

**Campaign Commands**:
```
xcp                     List campaign mobs
xcp <index>             Navigate to campaign mob
```

**Settings Commands**:
```
xset mark               Mark current room as area start
xset speed [walk|run]   Set/toggle movement speed
xset pk                 Toggle PK room display
xset vidblain           Toggle vidblain area hack
xset reset gui          Reset GUI window position
```

**Utility Commands**:
```
roomnote                Show notes for current room
roomnote area           Show all notes in current area

xhelp [<command>]       Show help for command
xhelp                   Show all commands
```

### 7.6 Testing Checklist

**Unit Tests**:
- [ ] String parsing (ANSI stripping)
- [ ] Room search algorithms
- [ ] Path finding
- [ ] Campaign parsing
- [ ] Configuration saving/loading

**Integration Tests**:
- [ ] GMCP event handling
- [ ] Mapper API integration
- [ ] Command queueing
- [ ] GUI rendering

**Functional Tests**:
- [ ] Hunt trick with 1, 5, 10, 20 sequential mobs
- [ ] Auto-hunt across different terrain types
- [ ] Quick where with single and multiple results
- [ ] Area navigation with unmapped/partially mapped areas
- [ ] Campaign workflow for area and room campaigns
- [ ] Edge cases: invalid inputs, disconnection, combat interruption

**Performance Tests**:
- [ ] Search 10,000+ room database
- [ ] Rapid command execution
- [ ] Memory leak detection (long-running session)
- [ ] GUI responsiveness under load

**User Acceptance Tests**:
- [ ] New user onboarding
- [ ] Power user workflow
- [ ] Configuration persistence
- [ ] Error message clarity
- [ ] Help documentation completeness

---

## 8. Policy Compliance Verification

### 8.1 Legal Use Cases (✅ Verified)

**Hunt Trick**:
- ✅ Player initiates each hunt sequence
- ✅ Player must type `ht abort` to stop
- ✅ No automatic killing

**Auto Hunt**:
- ✅ Player types `ah <mob>` for each hunt
- ✅ Stops automatically on combat (safety)
- ✅ Player must manually kill mob

**Campaign Management**:
- ✅ Displays information only
- ✅ Player must type `xcp <index>` for each mob
- ✅ Navigation only, no auto-completion

### 8.2 Safety Mechanisms (Required)

**Combat Detection**:
```lua
-- Must stop auto-hunt immediately on combat
registerAnonymousEventHandler("gmcp.char.status", function()
    if gmcp.char.status.state == "combat" then
        if SnD.state.auto_hunt_active then
            SnD.log("info", "Auto-hunt aborted: Combat detected")
            SnD.state.auto_hunt_active = false
        end
    end
end)
```

**AFK Detection**:
```lua
-- If Telnet 102 available, detect AFK
registerAnonymousEventHandler("gmcp.char.status", function()
    if gmcp.char.status.state == "afk" then
        -- Disable all automation
        SnD.state.hunt_sequence = nil
        SnD.state.auto_hunt_active = false
        SnD.log("warn", "All automation disabled: AFK detected")
    end
end)
```

**Sequence Limits**:
```lua
-- Prevent infinite loops
if SnD.config.hunt.max_sequential_hunts and 
   hunt_count > SnD.config.hunt.max_sequential_hunts then
    SnD.log("warn", "Hunt sequence limit reached, aborting")
    abort_hunt()
end
```

### 8.3 Prohibited Features (❌ Must Not Implement)

**DO NOT**:
- ❌ Auto-kill on room entry
- ❌ Auto-loot triggers
- ❌ Repeat hunt/kill without manual command
- ❌ Campaign auto-completion loops
- ❌ Any feature that works while AFK
- ❌ Stacked commands that clear areas

**Code Review Checklist**:
```
[ ] No triggers on room entry that attack mobs
[ ] No automated kill sequences
[ ] All actions require explicit player command
[ ] Combat stops all automation
[ ] AFK detection (if available) disables features
[ ] No experience gain without player interaction
```

---

## 9. Mudlet Modern Standards Compliance

### 9.1 Package Structure

**Recommended**: Mudlet Package (.mpackage format)
```
SearchAndDestroy.mpackage/
├── mpackage                    # Package manifest
├── src/
│   ├── scripts/
│   │   ├── core.lua           # Main logic
│   │   ├── hunt.lua           # Hunt/Auto-hunt
│   │   ├── mapper.lua         # Mapper extender
│   │   ├── campaign.lua       # Campaign management
│   │   └── gui.lua            # UI components
│   ├── triggers/
│   │   ├── hunt_responses.lua
│   │   ├── where_parsing.lua
│   │   └── combat_detection.lua
│   └── aliases/
│       ├── hunt_commands.lua
│       ├── mapper_commands.lua
│       └── settings.lua
├── config/
│   └── defaults.lua           # Default configuration
├── assets/
│   ├── icons/                 # UI icons
│   └── sounds/               # Optional audio feedback
├── docs/
│   ├── README.md
│   ├── INSTALL.md
│   ├── COMMANDS.md
│   └── POLICY.md             # Automation policy warning
└── tests/
    └── unit_tests.lua
```

### 9.2 Code Style Guidelines

**Naming Conventions**:
```lua
-- Global namespace
SnD = SnD or {}               -- PascalCase for global

-- Module naming
SnD.Hunt = {}                  -- Modules PascalCase
SnD.Mapper = {}
SnD.Campaign = {}

-- Functions snake_case
function SnD.Hunt.execute_hunt_trick(mob)
    -- ...
end

-- Private functions prefix with _
local function _parse_hunt_output(line)
    -- ...
end

-- Constants UPPER_CASE
local MAX_HUNT_SEQUENCE = 20
local DEFAULT_MOVEMENT_SPEED = "run"
```

**Documentation**:
```lua
--- Executes a hunt trick sequence for the specified mob.
-- Automatically hunts numbered instances (1.mob, 2.mob, etc.)
-- until no more instances are found or user aborts.
-- @param mob string The mob keyword to hunt
-- @param starting_index number Optional starting index (default: 1)
-- @return boolean Success indicator
-- @usage SnD.Hunt.execute_hunt_trick("citizen", 3)
function SnD.Hunt.execute_hunt_trick(mob, starting_index)
    -- ...
end
```

### 9.3 Event System

**Use Modern Event Handlers**:
```lua
-- Good: Named event handler (can be killed later)
SnD.event_handlers = SnD.event_handlers or {}

SnD.event_handlers.room_change = registerAnonymousEventHandler(
    "gmcp.room.info", 
    "SnD.Mapper.handle_room_change"
)

-- Can disable/enable
killAnonymousEventHandler(SnD.event_handlers.room_change)

-- Bad: Old-style global function
function onGMCProominfo()  -- Avoid this pattern
    -- ...
end
```

### 9.4 UI Framework

**Use Geyser (not legacy positioning)**:
```lua
-- Good: Geyser-based UI
SnD.GUI = SnD.GUI or {}
SnD.GUI.main = Geyser.Container:new({
    name = "SnD_Main",
    x = "70%", y = "70%",
    width = "30%", height = "30%"
})

-- Bad: Absolute pixel positioning
SnD.GUI.main = createLabel("SnD_Main", 500, 500, 300, 200, 1)
```

### 9.5 State Persistence

**Use Profile Tables**:
```lua
-- Automatically saved between sessions
SnD.config = SnD.config or {
    movement = {
        default_speed = "run"
    }
}

-- For area start rooms (per character)
SnD.char_data = SnD.char_data or {}
SnD.char_data.area_starts = SnD.char_data.area_starts or {}

-- Multi-character support
local char_name = gmcp.char.base.name or "default"
SnD.char_data[char_name] = SnD.char_data[char_name] or {}
```

### 9.6 Error Handling

**Graceful Degradation**:
```lua
function SnD.Mapper.speedwalk_to_room(room_id)
    -- Check prerequisites
    if not getRoomID() then
        SnD.log("error", "Cannot determine current location")
        return false
    end
    
    if not roomExists(room_id) then
        SnD.log("error", string.format(
            "Target room %d not found in mapper database", 
            room_id
        ))
        return false
    end
    
    -- Attempt pathfinding
    local path = getPath(getRoomID(), room_id)
    if not path then
        SnD.log("warn", string.format(
            "No path found to room %d. Is it unmapped?", 
            room_id
        ))
        return false
    end
    
    -- Execute speedwalk
    local success, error = pcall(speedWalk, path)
    if not success then
        SnD.log("error", string.format(
            "Speedwalk failed: %s", 
            error
        ))
        return false
    end
    
    return true
end
```

### 9.7 Testing Integration

**Unit Test Framework**:
```lua
-- tests/unit_tests.lua
SnD.Tests = SnD.Tests or {}

function SnD.Tests.test_parse_mob_name()
    local test_cases = {
        {input = "citizen", expected = "citizen"},
        {input = "3.citizen", expected = "citizen"},
        {input = "large rat", expected = "large rat"},
    }
    
    for _, test in ipairs(test_cases) do
        local result = SnD.Hunt._parse_mob_name(test.input)
        assert(result == test.expected, 
               string.format("Expected %s, got %s", 
                            test.expected, result))
    end
    
    cecho("\n<green>✓ test_parse_mob_name passed\n")
end

-- Run all tests
function SnD.Tests.run_all()
    for name, test_func in pairs(SnD.Tests) do
        if name:match("^test_") then
            test_func()
        end
    end
    cecho("\n<yellow>All tests completed.\n")
end
```

---

## 10. Additional Considerations

### 10.1 Telnet Option 102 Integration (Future)

Aardwolf's Telnet 102 provides additional state information:
```lua
-- Example 102 data
channel102 = {
    [100] = 4,  -- State: 4 = AFK
    [101] = 1,  -- Login complete
    -- ... more options
}

-- If available in Mudlet:
function SnD.detect_afk()
    if channel102 and channel102[100] == 4 then
        return true
    end
    return false
end
```

### 10.2 Multi-Character Support

```lua
-- Per-character configuration
local char_name = gmcp.char.base.name

SnD.characters = SnD.characters or {}
SnD.characters[char_name] = SnD.characters[char_name] or {
    area_starts = {},
    campaign_history = {},
    preferences = {}
}

-- Active character reference
SnD.active_char = SnD.characters[char_name]
```

### 10.3 Cross-Platform Compatibility

**File Paths**:
```lua
-- Use Mudlet's getMudletHomeDir()
local home = getMudletHomeDir()
local config_path = home .. "/SnD_config.lua"

-- NOT: hard-coded paths
-- local config_path = "C:\\Users\\...\\SnD_config.lua"  -- Windows only!
```

**Path Separator**:
```lua
local sep = package.config:sub(1,1)  -- "/" or "\\"
local path = home .. sep .. "SnD" .. sep .. "config.lua"
```

### 10.4 Internationalization (Optional)

```lua
SnD.locale = SnD.locale or "en_US"

SnD.strings = {
    en_US = {
        hunt_not_found = "Cannot hunt that mob",
        hunt_success = "Hunt successful",
        abort_message = "Operation aborted by user"
    },
    -- Add more languages if needed
}

function SnD.t(key)
    return SnD.strings[SnD.locale][key] or key
end
```

### 10.5 Accessibility

**Screen Reader Support**:
- Use clear, descriptive output messages
- Avoid pure visual indicators
- Provide audio feedback option

```lua
if SnD.config.accessibility.screen_reader_mode then
    -- Use plain text output instead of GUI
    cecho(string.format("\n<green>Hunt Result:<reset> %s\n", message))
else
    -- GUI display
    campaign_window:echo(formatted_html)
end
```

---

## 11. Conclusion

### 11.1 Summary

Search and Destroy represents a sophisticated quality-of-life tool that enhances the Aardwolf MUD experience while carefully maintaining compliance with automation policies. A successful Mudlet port requires:

1. **Deep understanding of Aardwolf's policy boundaries** - The plugin must provide navigation and information assistance without crossing into automation that gains experience or completes tasks without player interaction.

2. **Robust GMCP integration** - Mudlet's native GMCP support simplifies implementation but requires careful event handling and state management.

3. **Mapper abstraction layer** - Bridging the differences between MUSHclient's SQLite mapper and Mudlet's internal mapper requires a well-designed API abstraction.

4. **Modern Mudlet standards** - Following Geyser UI patterns, event-driven architecture, and proper module structure ensures long-term maintainability.

5. **Comprehensive testing** - Given the complexity of mob hunting, pathfinding, and campaign management, thorough testing at all levels is essential.

### 11.2 Success Criteria

A successful Mudlet port of Search and Destroy will:

✅ Provide **feature parity** with the MUSHclient version  
✅ Maintain **strict policy compliance** - legal by design  
✅ Offer **superior user experience** through modern Mudlet UI  
✅ Demonstrate **robust error handling** and graceful degradation  
✅ Include **comprehensive documentation** and help system  
✅ Support **multi-character** workflows  
✅ Enable **community contribution** through clean code and testing  

### 11.3 Risk Mitigation

**Policy Risks**:
- **Risk**: Users modify plugin to auto-kill, violating policies
- **Mitigation**: Clear documentation, warnings in code, community education

**Technical Risks**:
- **Risk**: Mapper database incompatibilities
- **Mitigation**: Abstraction layer, extensive testing, graceful fallbacks

**Community Risks**:
- **Risk**: Low adoption due to Mudlet's smaller Aardwolf community
- **Mitigation**: Cross-promotion, feature advantages over MUSHclient version

### 11.4 Next Steps

1. **PRD Creation**: Use this analysis to create formal Product Requirements Document
2. **Technical Design**: Detail system architecture and class diagrams
3. **Prototype Development**: Build Phase 1 MVP for core functionality testing
4. **Alpha Testing**: Limited release to experienced Aardwolf/Mudlet users
5. **Iteration**: Refine based on feedback
6. **Documentation**: Comprehensive user and developer docs
7. **Public Release**: GitHub repository, Mudlet package manager submission
8. **Community Support**: Forum presence, bug tracking, feature requests

---

## Appendix A: References

### Official Documentation
- **Aardwolf Wiki**: https://www.aardwolf.com/wiki/
- **Aardwolf GMCP Reference**: https://www.aardwolf.com/wiki/index.php/Clients/GMCP
- **Mudlet Wiki**: https://wiki.mudlet.org/
- **Mudlet API Reference**: https://wiki.mudlet.org/w/Manual:Lua_Functions

### Source Repositories
- **Search and Destroy (Crowley)**: https://github.com/AardCrowley/Search-and-Destroy
- **WinkleWinkle Triple Pack**: https://github.com/aardwolf-lunk/WinkleWinkle-Search-And-Destroy-Triple-Pack-Up-To-Date
- **MUSHclient Aardwolf Package**: https://github.com/fiendish/aardwolfclientpackage
- **Mudlet Aardwolf GUI (MAG)**: Referenced on Aardwolf Wiki

### Mudlet Examples
- **Jieiku AardwolfMudlet**: https://github.com/Jieiku/AardwolfMudlet
- **Daagar DAMP**: https://github.com/daagar/damp

### Policy Documents
- **Aardwolf Automation Policy**: https://www.aardwolf.com/wiki/index.php/Help:Botting
- **Player Code of Conduct**: Available in-game via `help rules`

---

## Appendix B: Glossary

**Terms and Abbreviations**:

- **AFK**: Away From Keyboard - Player not actively present
- **Campaign**: Quest system in Aardwolf where players hunt specific mobs
- **Cexit**: Custom exit in mapper (player-created shortcuts)
- **GMCP**: Generic Mud Communication Protocol - Out-of-band data channel
- **Gquest**: Global quest (server-wide cooperative quest)
- **Hunt Trick**: Sequential hunting through numbered mob instances
- **MUD**: Multi-User Dungeon - Text-based multiplayer game
- **Speedwalk**: Rapid automated movement through multiple rooms
- **Telnet 102**: Aardwolf-specific telnet option for configuration
- **Vnum**: Virtual number - Unique room identifier
- **Where**: Aardwolf command to locate mobs in the game world

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Author**: Research compilation for Mudlet port initiative  
**Status**: Ready for PRD creation and development planning
