# Search and Destroy Mudlet Port - Architecture Analysis

**Issue:** as-1tn
**Date:** 2026-02-10
**Status:** Investigation Complete

---

## 1. Executive Summary

The Mudlet port of Aardwolf's Search and Destroy (SnD) plugin exists at `crew/ericfriday/mudlet-snd-flattened/packages/search-and-destroy/src/` as 15 Lua source files totaling **906 lines**. It implements a clean, event-driven architecture targeting Mudlet's native APIs, with a compatibility/mock layer for development outside the Mudlet runtime.

The port covers the **core feature set** of the original SnD plugin but represents roughly **8-12%** of the original's functional surface area. The original Crowley version alone contains 10,110 lines with 360 functions, 95 aliases, and 164 triggers. The WinkleWinkle Triple Pack adds another ~3,500 lines across 3 plugins.

**Bottom line:** The port has solid architectural foundations and correct module boundaries, but most modules are skeleton implementations (~20-50 lines each) rather than production-ready code. Significant implementation work remains.

---

## 2. Original Source Inventory

### 2.1 Source Materials Present

All original source files are preserved in `crew/ericfriday/snd-original/`:

| Source | Files | Language | Lines | Description |
|--------|-------|----------|-------|-------------|
| Search-and-Destroy-master (Crowley v5.99) | 1 XML | Lua | 10,110 | Latest maintained version. Most comprehensive |
| WinkleWinkle Triple Pack | 3 XML | Lua | ~3,500 | Original author's modular version |
| WinkleWinkle v2.8.1 (2012 archive) | 3 XML | Lua | ~3,500 | Archival copy |
| aardwolf-scriptalicious (SVN) | 6 XML + sounds | Mixed | ~2,000 | Accessory plugins (Hunt Trick, Quest Status, Jaws, etc.) |
| Standalone WinkleWinkle_Search_Destroy_2.xml | 1 XML | Lua | ~1,060 | Duplicate/reference |

**Key finding:** All original source is **Lua** (not VBScript), eliminating the VBScript translation risk identified in earlier analysis documents.

### 2.2 Original Architecture (MUSHclient)

The original SnD operates as 1-3 MUSHclient XML plugins:

**Crowley's version** — monolithic single plugin:
- 360 functions, 95 aliases, 164 triggers
- Built-in SQLite database for mob keywords and kill tracking
- GMCP integration via `OnPluginBroadcast()` + `CallPlugin()`
- Comprehensive state machine tracking character state, activity type
- Self-update system from GitHub
- 50+ combat damage verb triggers for last-mob tracking

**WinkleWinkle's version** — modular three-plugin architecture:
1. **Search_Destroy_2** (~1,060 lines) — Hunt trick, auto hunt, quick where, quick scan/kill
2. **Mapper_Extender_2** (~1,816 lines) — Area navigation, room search, campaign display, start rooms
3. **Extender_GUI_2** (~564 lines) — Miniwindow with buttons and clickable target lists

Inter-plugin communication via `OnPluginBroadcast()` message passing.

---

## 3. Mudlet Port Module Inventory

### 3.1 File Map

```
mudlet-snd-flattened/packages/search-and-destroy/src/
  core.lua           246 lines   Core namespace, mock compatibility layer
  hunt.lua            63 lines   Hunt trick automation
  campaign.lua        48 lines   Campaign navigation logic
  campaign_gui.lua    28 lines   Campaign GUI display
  mapper.lua          45 lines   Area navigation (xrunto, setStartRoom)
  gui.lua             42 lines   Main GUI window initialization
  buttons.lua         43 lines   Control button panel
  aliases.lua         23 lines   Command alias definitions
  database.lua        92 lines   SQLite persistence layer
  gmcp.lua            17 lines   GMCP event handlers
  quick_where.lua     43 lines   Quick where mob location
  realtime.lua        25 lines   Enhanced quest processing
  mock_data.lua       93 lines   Mock data for testing
  test_functions.lua  67 lines   Mudlet function availability tests
  test_phase2.lua     31 lines   Phase 2 integration tests
                     ─────
  TOTAL              906 lines
```

### 3.2 Module Completion Status

| Module | Lines | Status | Notes |
|--------|-------|--------|-------|
| **core.lua** | 246 | Complete | Namespace init, mock/compat layer, version 1.0.0 |
| **hunt.lua** | 63 | Skeleton | Has execute/next/abort. Missing: direction parsing, confidence levels, auto-hunt movement, combat abort |
| **campaign.lua** | 48 | Skeleton | Has list/goto/process. Missing: GMCP comm.quest parsing, area vs room type detection, dead mob tracking |
| **campaign_gui.lua** | 28 | Skeleton | Has updateCampaigns. Missing: color coding, dead status, level range display, GQ mode |
| **mapper.lua** | 45 | Skeleton | Has setStartRoom/xrunto. Missing: xm/xmall room search, go/nx navigation, vidblain handling, room notes |
| **gui.lua** | 42 | Skeleton | Window/layout creation. Missing: styling, resize persistence, minimize/maximize |
| **buttons.lua** | 43 | Partial | Toggle/Update buttons work. Settings panel marked "not yet implemented" |
| **aliases.lua** | 23 | Skeleton | 4 aliases (setstart, xrt, xcp, qw). Missing: ht, ah, ak, qs, go, nx, xm, xmall, roomnote, xset |
| **database.lua** | 92 | Complete | Schema, CRUD for targets/starts/config. Well-structured |
| **gmcp.lua** | 17 | Skeleton | Room + quest handlers registered. Missing: char.status, combat detection, state tracking |
| **quick_where.lua** | 43 | Skeleton | Has execute. Missing: response parsing triggers, multiple-result handling, clickable links |
| **realtime.lua** | 25 | Skeleton | Campaign + GQ event routing. Missing: quest type detection, timer management |
| **mock_data.lua** | 93 | Complete | Full mock environment for dev/test |
| **test_functions.lua** | 67 | Complete | Function availability validation |
| **test_phase2.lua** | 31 | Complete | Integration test for Phase 2 |

**Summary:** 4/15 files are complete (core, database, mock_data, test infrastructure). 10/15 are skeleton implementations with correct structure but minimal logic. 1/15 is partial.

---

## 4. Architecture Overview

### 4.1 Design Philosophy

The port follows a **decoupled, event-driven architecture** — the correct approach for Mudlet:

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Aliases    │────>│  Core Logic   │────>│   Database   │
│  (aliases)   │     │ (hunt/camp/   │     │  (database)  │
│              │     │  mapper/qw)   │     │              │
└─────────────┘     └──────┬───────┘     └──────────────┘
                           │
              raiseEvent() │ registerAnonymousEventHandler()
                           │
                    ┌──────▼───────┐
                    │     GUI      │
                    │ (gui/buttons/│
                    │  camp_gui)   │
                    └──────────────┘
                           ▲
                           │
                    ┌──────┴───────┐
                    │    GMCP      │
                    │ (gmcp/       │
                    │  realtime)   │
                    └──────────────┘
```

**Key design decisions:**
1. **Global namespace:** `SnD = {}` with sub-modules (`SnD.Hunt`, `SnD.Campaign`, `SnD.Mapper`, `SnD.GUI`, `SnD.Database`)
2. **Event communication:** Modules communicate via `SnD.raiseEvent()` / `SnD.registerHandler()`, not direct function calls
3. **Mock compatibility:** `core.lua` provides mock implementations of all Mudlet APIs, allowing development/testing outside Mudlet
4. **Persistence via SQLite:** `database.lua` uses Mudlet's `db:create()` API with three tables: targets, area_starts, config
5. **Map data via UserData API:** `mapper.lua` uses `setAreaUserData()` / `getAllAreaUserData()` for start rooms — the correct Mudlet-native approach

### 4.2 Module Dependencies

```
core.lua ← (all modules depend on this)
  ├── hunt.lua         (standalone, uses send/cecho)
  ├── campaign.lua     (depends on mapper.lua for xrunto)
  ├── mapper.lua       (uses Mudlet Mapper API)
  ├── quick_where.lua  (uses send, tempRegexTrigger, Mapper API)
  ├── database.lua     (uses Mudlet db: API)
  ├── gmcp.lua         (registers GMCP event handlers)
  ├── realtime.lua     (depends on campaign, database)
  ├── gui.lua          (uses Geyser framework)
  │   ├── buttons.lua  (depends on gui.lua)
  │   └── campaign_gui.lua (depends on gui.lua)
  ├── aliases.lua      (registers permAlias, calls other modules)
  ├── mock_data.lua    (test-only, overrides core mocks)
  ├── test_functions.lua (test-only)
  └── test_phase2.lua   (test-only)
```

### 4.3 Data Flow

**Campaign workflow:**
```
GMCP comm.quest → gmcp.lua → SnD.Campaign.process()
                                    │
                                    ├──> SnD.Database.saveCampaignTargets()
                                    │
                                    └──> raiseEvent("campaignsUpdated")
                                              │
                                              └──> SnD.GUI.updateCampaigns()
```

**Hunt trick workflow:**
```
User types "ht citizen" → aliases.lua → SnD.Hunt.execute("citizen")
                                              │
                                              ├──> send("hunt 1.citizen")
                                              │
                                              └──> [trigger response] → SnD.Hunt.next()
                                                                            │
                                                                            └──> send("hunt 2.citizen")
                                                                                    ... until abort/not found
```

**xrunto workflow:**
```
User types "xrt midgaard" → aliases.lua → SnD.Mapper.xrunto("midgaard")
                                                │
                                                ├──> getAreaTable() — find area ID
                                                ├──> getAllAreaUserData(areaID) — get start room
                                                ├──> mmp.findRoute(current, startRoom)
                                                └──> walkTo(path)
```

---

## 5. Gap Analysis

### 5.1 Feature Coverage vs Original

| Feature Category | Original (Crowley) | Original (WinkleWinkle) | Mudlet Port | Gap |
|-----------------|-------------------|------------------------|-------------|-----|
| **Hunt Trick** | Full: indexed hunting, exact match, abort | Full: ht, ht N.mob, abort | Skeleton: execute/next/abort stubs | Large |
| **Auto Hunt** | Full: direction parsing, movement, combat abort | Full: confidence levels, directional | Not implemented | Critical |
| **Quick Where** | Full: mapper integration, hyperlinks | Full: where parsing, room matching | Skeleton: basic execute | Large |
| **Quick Scan** | Full: qs command | Full: qs command | Not implemented | Medium |
| **Quick Kill** | Full: ak/kk/qk with configurable command | Full: ak/autokill | Not implemented | Medium |
| **Campaign System** | Advanced: area/room detection, dead tracking, level filtering | Full: CP check, hyperlinks, level ranges | Skeleton: list/goto stubs | Large |
| **GQ System** | Full: join/track/complete, timer | Display only | Not implemented | Medium |
| **Quest System** | Full: GMCP quest mob targeting | Full: GMCP targeting | Minimal: in realtime.lua | Medium |
| **Mapper - xrunto** | Full: area matching, vidblain | Full: area matching, start rooms, vidblain | Skeleton: basic path | Medium |
| **Mapper - xm/xmall** | Full: room search, area filtering | Full: exact/partial, area/global | Not implemented | Large |
| **Mapper - go/nx** | Full: navigate search results | Full: go/nx with index | Not implemented | Large |
| **Mapper - xset mark** | Full: save start room | Full: save to DB | Implemented | Complete |
| **Room Notes** | Full: roomnote, roomnote area | Full: room/area notes | Not implemented | Medium |
| **GUI Window** | N/A (Crowley has no GUI) | Full: miniwindow, buttons, click | Skeleton: Geyser framework | Large |
| **Combat Tracking** | 50+ damage verb triggers | N/A | Not implemented | Low priority |
| **Mob Keyword Learning** | Full: SQLite, gmkw() | Full: guess_mob_name() | Not implemented | Medium |
| **Auto No-Exp** | Full: TNL threshold | N/A | Not implemented | Low priority |
| **State Machine** | Full: character state tracking | Basic: room/quest | Minimal: in gmcp.lua | Medium |
| **Self-Update** | Full: GitHub check | N/A | Not needed | N/A |
| **PK Room Toggle** | Full: xset pk | Full: xset pk | Not implemented | Low |
| **Vidblain Handling** | Full: portal detection | Full: vidblain nav | Not implemented | Low |
| **Speed Walk Toggle** | Full: walk/run | Full: xset speed | Not implemented | Low |
| **Area Level Index** | Full: level range filtering | Full: level capture | Not implemented | Medium |

### 5.2 Missing Aliases (12 of ~30 implemented)

**Implemented (4):**
- `snd setstart` — mark area start room
- `xrunto` / `xrt <area>` — run to area
- `xcp [N]` — campaign navigation
- `qw <mob>` — quick where

**Missing critical aliases:**
- `ht [N.]<mob>` / `ht abort` — hunt trick
- `ah <mob>` / `ah abort` — auto hunt
- `ak` / `kk` — quick kill
- `qs` — quick scan
- `go [N]` / `nx` — navigate search results
- `xm <room>` / `xmall <room>` — room search
- `roomnote` / `roomnote area` — mapper notes
- `xset speed` / `xset pk` / `xset vidblain` — settings
- `cp check` / `cp info` — campaign info
- `gq info` / `gq check` — global quest

### 5.3 Missing Triggers

The port has **zero MUD output triggers**. The original plugins define 29-164 triggers for:
- Hunt result parsing (direction, confidence, success/fail)
- Auto-hunt movement (6+ directional triggers)
- Combat damage verbs (50+ triggers in Crowley)
- Campaign check output parsing
- GQ output parsing
- Quest status changes
- Area index capture

This is the single largest implementation gap.

---

## 6. Technology Assessment

### 6.1 Build System

The project uses an **Nx monorepo** with pnpm, but this is scaffolding only:
- No TypeScript source files exist
- No `bun` configuration (despite task instructions mentioning `bun test`)
- All source is Lua (`.lua` files)
- No actual build step compiles or transforms the Lua
- No test runner is configured for Lua

**Assessment:** The Nx/pnpm/TypeScript toolchain is vestigial. The project is a pure Lua codebase that needs to run inside Mudlet's Lua 5.1 runtime. A Lua test runner (like busted or the existing mock framework) would be more appropriate.

### 6.2 Mudlet API Usage

The port correctly targets modern Mudlet APIs:

| API | Used For | Status |
|-----|----------|--------|
| `Geyser.UserWindow` | Main GUI window | Mocked, correct usage |
| `Geyser.VBox/HBox/Label/Container` | Layout | Mocked, correct usage |
| `registerAnonymousEventHandler` | GMCP events | Mocked, correct usage |
| `raiseEvent` | Inter-module events | Mocked, correct usage |
| `setAreaUserData` / `getAllAreaUserData` | Start room persistence | Mocked, correct usage |
| `getAreaTable` / `getRoomArea` / `getRoomAreaName` | Area lookup | Mocked, correct usage |
| `mmp.findRoute` / `walkTo` | Pathfinding + movement | Mocked, correct usage |
| `db:create` / `db:save` | SQLite persistence | Mocked, correct usage |
| `tempRegexTrigger` | Dynamic trigger creation | Mocked, correct usage |
| `cecho` | Colored output | Mocked, correct usage |
| `send` | MUD commands | Mocked, correct usage |

**Assessment:** API choices are correct and follow Mudlet best practices. The mock layer in `core.lua` is well-designed for development outside Mudlet.

### 6.3 Code Quality

**Strengths:**
- Clean module separation following the decoupled architecture recommended in the PRD
- Consistent naming conventions (PascalCase modules, camelCase functions)
- Event-driven communication between modules
- Database schema is well-designed with proper tables
- Mock layer enables testing without Mudlet runtime

**Weaknesses:**
- Most modules are stub/skeleton implementations (20-50 lines)
- No actual trigger definitions for parsing MUD output
- No error handling in any module
- No input validation
- No configurable settings (movement speed, kill command, etc.)
- Test files only validate mock function availability, not actual logic

---

## 7. Dependency Map

```
External Dependencies:
  ├── Mudlet 4.10+ runtime (Lua 5.1)
  ├── Mudlet Geyser GUI framework
  ├── Mudlet Mapper (with Aardwolf map data)
  ├── Mudlet GMCP handler (built-in)
  ├── Mudlet SQLite (db: API)
  └── Aardwolf MUD server (GMCP data source)

Internal Module Dependencies:
  core.lua ──────────────────────────── Foundation (required by all)
    │
    ├── database.lua ─────────────── Standalone (core only)
    │
    ├── gmcp.lua ─────────────────── Standalone (core only)
    │
    ├── hunt.lua ─────────────────── Standalone (core only)
    │
    ├── quick_where.lua ──────────── Standalone (core only)
    │
    ├── mapper.lua ───────────────── Standalone (core only)
    │
    ├── campaign.lua ─────────────── Depends on: mapper.lua (xrunto)
    │
    ├── realtime.lua ─────────────── Depends on: campaign.lua, database.lua
    │
    ├── gui.lua ──────────────────── Standalone (core Geyser only)
    │   ├── buttons.lua ──────────── Depends on: gui.lua
    │   └── campaign_gui.lua ─────── Depends on: gui.lua
    │
    ├── aliases.lua ──────────────── Depends on: mapper, campaign, quick_where
    │
    └── [Test files] ─────────────── Depends on: core, database, mock_data
```

---

## 8. Existing Documentation

Two comprehensive analysis documents exist in `crew/ericfriday/`:

1. **Search_and_Destroy_Mudlet_Port_Analysis.md** (1,430 lines) — Detailed PRD-style document covering:
   - Core functionality breakdown (ht, ah, qw, ak, qs, mapper, campaign)
   - MUSHclient technical architecture with code examples
   - Aardwolf automation policy compliance analysis
   - Mudlet API mapping (GMCP, Mapper, Geyser, SQLite)
   - 6-phase implementation roadmap
   - Configuration schema, command reference, testing checklist
   - Performance targets and error handling spec

2. **Porting Aardwolf Search and Destroy.md** (357 lines) — Strategic porting blueprint:
   - Architectural reimplementation rationale (not line-by-line translation)
   - MUSHclient-to-Mudlet technology translation table
   - Decoupled event-driven design recommendation
   - Phased development plan (3 phases)
   - Risk analysis with mitigations

Both documents are thorough and well-researched. The port's architecture follows their recommendations correctly.

---

## 9. Recommendations

### 9.1 Immediate Priority (P1)

1. **Implement MUD output triggers** — The port has zero triggers. Without these, no feature actually works against a live Aardwolf connection. Priority triggers:
   - Hunt result parsing (success/fail/direction)
   - Where command response parsing
   - Campaign check output parsing

2. **Complete hunt.lua** — The hunt trick is the most-used feature. Needs direction parsing, confidence levels, auto-hunt movement logic, combat abort detection.

3. **Add missing critical aliases** — `ht`, `ah`, `ak`, `qs` are the daily-use commands.

### 9.2 Medium Priority (P2)

4. **Implement auto-hunt** — Separate module or expand hunt.lua. Needs directional movement automation with combat abort.

5. **Complete campaign system** — GMCP parsing, area/room type detection, CP check output parsing.

6. **Implement room search** — `xm`/`xmall`/`go`/`nx` for mapper navigation.

7. **Add mob name guessing** — Port `guess_mob_name()` logic from WinkleWinkle or `gmkw()` from Crowley.

### 9.3 Low Priority (P3)

8. **Replace Nx scaffolding** — Either add a Lua test runner (busted) or remove the Nx/pnpm/TypeScript tooling entirely.

9. **GUI polish** — Styling, state persistence, minimize/maximize, drag support.

10. **Advanced features** — GQ tracking, combat verb triggers, auto no-exp, vidblain handling.

### 9.4 Build/Test Note

The task instructions reference `bun test` and `bun run build` in `crew/ericfriday/game/`, but:
- No `game/` directory exists; code is in `mudlet-snd-flattened/`
- No `bun` configuration exists; project uses `pnpm` + Nx
- No dependencies are installed (`node_modules/` missing)
- The source is pure Lua with no TypeScript to compile
- Tests validate mock function availability only, not business logic

**The project cannot be built or tested in its current state** without either installing pnpm dependencies or creating a Lua-native test harness.

---

## 10. Summary

| Metric | Value |
|--------|-------|
| Port source files | 15 Lua files |
| Port total LOC | 906 lines |
| Original LOC (Crowley) | 10,110 lines |
| Original LOC (WinkleWinkle 3-pack) | ~3,500 lines |
| Feature coverage | ~15-20% of original surface area |
| Architecture quality | Good (correct patterns, API choices) |
| Implementation completeness | Low (mostly skeletons) |
| MUD triggers implemented | 0 |
| Aliases implemented | 4 of ~30 |
| Modules complete | 4/15 (core, database, mock, tests) |
| Modules skeleton | 10/15 |
| Modules partial | 1/15 (buttons) |
| Build system | Non-functional (Nx scaffolding, no Lua runner) |
| Documentation | Excellent (2 comprehensive analysis docs) |

The Mudlet SnD port has **correct architecture and good foundations** but is in **early development** — closer to a proof-of-concept than a working port. The mock compatibility layer and database module are production-quality. Everything else needs significant implementation work to reach feature parity with even the simpler WinkleWinkle version.
