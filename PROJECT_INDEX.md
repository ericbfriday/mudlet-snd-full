# Project Index: Mudlet Search and Destroy

Generated: 2026-01-21

## Overview

Mudlet SnD is a comprehensive port of the Aardwolf Search and Destroy plugin to Mudlet, implementing type-safe Lua code with modern development practices. The project uses Nx monorepo architecture to manage multiple packages and development workflows.

## 📁 Project Structure

```
mudlet-snd/
├── mudlet-snd/                    # Primary Nx workspace implementation
│   └── packages/
│       └── search-and-destroy/    # Main S&D package
│           └── src/               # 20 Lua source files
├── mudlet-snd-flattened/          # Flattened workspace variant
│   └── packages/
│       └── search-and-destroy/    # Flattened S&D package
│           └── src/               # 16 Lua source files
├── snd-original/                  # Original source references
│   ├── 20120510_b_Search_and_Destroy_v2.8.1/
│   ├── WinkleWinkle-Search-And-Destroy-Triple-Pack-Up-To-Date-master/
│   └── Search-and-Destroy-master/
├── thoughts/                      # Planning and documentation
│   ├── plans/                     # Implementation plans
│   ├── research/                  # Research documents
│   └── tickets/                   # Feature tickets
└── .opencode/                     # OpenCode AI integration
```

## 🚀 Entry Points

### Main Implementation (mudlet-snd/)
- **Core**: `mudlet-snd/packages/search-and-destroy/src/core.lua` - Global namespace, compatibility layer, initialization
- **Database**: `mudlet-snd/packages/search-and-destroy/src/database.lua` - SQLite persistence layer (14KB)
- **Mapper**: `mudlet-snd/packages/search-and-destroy/src/mapper.lua` - Mudlet mapper integration
- **GMCP**: `mudlet-snd/packages/search-and-destroy/src/gmcp.lua` - Game data event handlers
- **Config Manager**: `mudlet-snd/packages/search-and-destroy/src/config_manager.lua` - Configuration management (6.4KB)

### Flattened Implementation (mudlet-snd-flattened/)
- **Core**: `mudlet-snd-flattened/packages/search-and-destroy/src/core.lua` - Same structure as main
- **Database**: `mudlet-snd-flattened/packages/search-and-destroy/src/database.lua` - Simplified version (2.6KB)

### Test Entry Points
- **Phase 1**: `mudlet-snd/packages/search-and-destroy/src/test_phase1_comprehensive.lua`
- **Phase 2**: `mudlet-snd/packages/search-and-destroy/src/test_phase2_enhanced.lua`
- **Mock Data**: `mudlet-snd/packages/search-and-destroy/src/mock_data.lua` - Test data framework (12KB)

## 📦 Core Modules

### 1. Core System (`core.lua` - 6.7KB)
- **Namespace**: `SnD` global table
- **Version**: 1.0.0
- **Exports**: Mudlet API compatibility layer, mock functions for testing
- **Dependencies**: Mudlet API functions (raiseEvent, cecho, walkTo, etc.)

### 2. Database Layer (`database.lua`)
**Main Version**: 14KB with full implementation
- Campaign target storage and retrieval
- Area start room configuration
- SQLite schema: targets, area_starts, config tables
- CRUD operations with error handling

**Flattened Version**: 2.6KB with basic implementation
- Simplified target management
- Core persistence functions only

### 3. Mapper Integration (`mapper.lua` - 1.4KB)
- Room navigation and pathfinding
- Area-based routing logic
- Mudlet mapper API integration

### 4. GMCP Handler (`gmcp.lua` - 711 bytes)
- Game event processing
- Room information updates
- Quest data synchronization

### 5. Campaign Management (`campaign.lua` - 1.3KB)
- Campaign target tracking
- Quest progression logic
- Target completion handling

### 6. GUI Components
- **Main GUI**: `gui.lua` (1.2KB) - Primary interface
- **Campaign GUI**: `campaign_gui.lua` (995 bytes) - Campaign display
- **Buttons**: `buttons.lua` (1.1KB) - UI controls

### 7. Hunting System (`hunt.lua` - 1.9KB)
- Target location and navigation
- Hunt command processing
- Path optimization

### 8. Support Modules
- **Quick Where**: `quick_where.lua` (1.4KB) - Fast location lookup
- **Realtime**: `realtime.lua` (938 bytes) - Real-time event processing
- **Aliases**: `aliases.lua` (996 bytes / 751 bytes) - Command aliases
- **Config Manager**: `config_manager.lua` (6.4KB) - Advanced configuration

### 9. Testing Infrastructure
- **Test Functions**: `test_functions.lua` (1.9KB)
- **Mock Data**: `mock_data.lua` (12KB / 2.3KB)
- **Phase Tests**: `test_phase2_enhanced.lua` (3.2KB)

## 🔧 Configuration

### Workspace Configuration
- **Nx**: `nx.json` - Monorepo build orchestration
- **TypeScript**: `tsconfig.base.json`, `tsconfig.json` - TS compilation config
- **Package**: `package.json` - Dependencies and scripts
- **Workspace**: `pnpm-workspace.yaml` - PNPM workspace definition

### Build & CI
- **GitHub Actions**: `.github/workflows/ci.yml` - Continuous integration
- **Project**: `project.json` - Nx project configuration
- **Lock Files**: `pnpm-lock.yaml` - Dependency versions

### IDE Integration
- **VSCode**: `.vscode/extensions.json` - Recommended extensions
- **Gemini**: `.gemini/settings.json` - AI assistant settings
- **Serena**: `.serena/project.yml` - Project metadata

## 📚 Documentation

### Project Documentation
- `README.md` (root) - Project overview
- `mudlet-snd/README.md` - Nx workspace guide
- `mudlet-snd-flattened/README.md` - Flattened workspace guide
- `AGENTS.md` (root) - Agent configurations

### Technical Analysis
- `Porting Aardwolf Search and Destroy.md` - Claude analysis of porting challenges
- `Search_and_Destroy_Mudlet_Port_Analysis.md` - Gemini deep research on porting

### Planning Documents (thoughts/)
- **Research**:
  - `2025-11-18_migration_workflow_research.md` - Migration workflow analysis
  - `phase2_data_storage_analysis.md` - Phase 2 data storage research

- **Plans**:
  - `2025-11-18_migration_workflow_implementation.md` - Migration implementation plan
  - `phase2_data_storage_implementation.md` - Phase 2 implementation plan

- **Tickets**:
  - `feature_migration_workflow.md` - Migration feature specification
  - `phase2_data_storage_implementation.md` - Phase 2 feature ticket

### Original Documentation (snd-original/)
- `Search-and-Destroy-master/README.md` - Original project docs
- `Search-and-Destroy-master/CREDIT.md` - Attribution
- `Search-and-Destroy-master/ReleaseChecklist.md` - Release process

## 🧪 Test Coverage

### Test Files
- Phase 1 comprehensive tests: 1 file (1.9KB)
- Phase 2 enhanced tests: 1 file (3.2KB)
- General test functions: 1 file (1.9KB)
- Mock data frameworks: 2 files (12KB + 2.3KB)

### Coverage Areas
- ✅ Core mapper logic (Phase 1 complete)
- 🚧 Database persistence (Phase 2 in progress)
- 🚧 GMCP integration (Phase 2 in progress)
- ✅ Mock data framework (established)

## 🔗 Key Dependencies

### Runtime Dependencies
- **Mudlet**: Lua 5.1+ runtime environment
- **Mudlet Mapper**: Built-in mapping system
- **GMCP**: Game communication protocol
- **SQLite**: Via Mudlet's database module

### Development Dependencies
- **Nx**: 22.0.4 - Monorepo management
- **TypeScript**: 5.9.2 - Type checking
- **SWC**: 1.5.7 - Fast compilation
- **Prettier**: 2.6.2 - Code formatting
- **PNPM**: Package management

### AI Integrations
- **OpenCode AI SDK**: Development assistance
- **Zod**: Schema validation (in .opencode/)

## 📊 Project Statistics

- **Total Lua Files**: 34
- **Total XML Files**: 14 (original sources)
- **Total Markdown Docs**: 33
- **Main Implementation**: 20 Lua files (~50KB total)
- **Flattened Implementation**: 16 Lua files (~23KB total)
- **Lines of Code**: ~2,500+ (main implementation)

## 🎯 Development Phases

### Phase 1: Core Mapper Logic ✅
- Area-based navigation
- Room tracking
- Basic pathfinding
- **Status**: Complete and tested

### Phase 2: Data Storage & GMCP 🚧
- SQLite database integration
- Campaign target persistence
- GMCP event handlers
- Mock data framework
- **Status**: In progress

### Phase 3: Campaign Management 📋
- Full campaign workflow
- Target tracking UI
- Quest integration
- **Status**: Planned

### Phase 4: Advanced Features 📋
- Real-time updates
- Quick where functionality
- Hunt optimization
- **Status**: Planned

## 📝 Quick Start

### Development Setup
```bash
cd mudlet-snd
pnpm install
```

### Build Project
```bash
npx nx build search-and-destroy
```

### Run Tests
```lua
-- In Mudlet console
lua dofile("packages/search-and-destroy/src/test_phase2_enhanced.lua")
```

### Graph Dependencies
```bash
npx nx graph
```

## 🔍 Key File Locations

### Most Active Development Files
1. `mudlet-snd/packages/search-and-destroy/src/database.lua` - Database layer
2. `mudlet-snd/packages/search-and-destroy/src/config_manager.lua` - Config system
3. `mudlet-snd/packages/search-and-destroy/src/mock_data.lua` - Test framework
4. `mudlet-snd/packages/search-and-destroy/src/core.lua` - Core namespace

### Reference Files
1. `snd-original/Search-and-Destroy-master/Search_and_Destroy.xml` - Original implementation
2. `snd-original/WinkleWinkle_Search_Destroy_2.xml` - WinkleWinkle variant

### Planning Files
1. `thoughts/tickets/phase2_data_storage_implementation.md` - Current work
2. `thoughts/plans/phase2_data_storage_implementation.md` - Implementation plan
3. `thoughts/research/phase2_data_storage_analysis.md` - Research notes

---

**Index Size**: ~5KB
**Last Updated**: 2026-01-21
**Token Efficiency**: 94% reduction vs full codebase read
**Estimated Full Codebase**: ~58,000 tokens
**Index Read Cost**: ~3,000 tokens
