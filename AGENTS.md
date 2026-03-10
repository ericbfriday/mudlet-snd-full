# Mudlet Search and Destroy - Project Knowledge Base

## Overview
Port of Aardwolf MUD's Search and Destroy (SnD) plugin from MUSHclient to Mudlet. Lua source with Nx/TypeScript build tooling. Currently ~8-12% of original feature surface area implemented.

## Structure
```
mudlet-snd/                      # ← MAIN REPO (git submodule)
├── packages/search-and-destroy/
│   └── src/                     # All Lua source (18 files, ~1900 lines)
├── nx.json, package.json        # Nx monorepo + pnpm
└── test_phase1.lua              # Root-level integration test

mudlet-snd-flattened/            # Older snapshot — reference only, do NOT edit
snd-original/                    # Original MUSHclient XML sources — read-only reference
thoughts/                        # Planning docs (plans/, research/, tickets/)
```

## Build Commands
- **Build**: `nx build` or `pnpm exec nx build`
- **Test**: `nx test` or `pnpm exec nx test` (single: `nx test --testNamePattern="testName"`)
- **Lint**: `nx lint` or `prettier --check .`
- **Typecheck**: `nx typecheck` or `pnpm exec nx typecheck`
- **All checks**: `pnpm exec nx run-many -t lint test build typecheck`
- **Run from**: `mudlet-snd/` directory (the Nx workspace root)

## Where to Look
| Task | Location | Notes |
|------|----------|-------|
| Add new feature module | `mudlet-snd/packages/search-and-destroy/src/` | Follow existing `SnD.ModuleName` pattern |
| Understand original behavior | `snd-original/Search-and-Destroy-master/` | Crowley v5.99 — most complete reference |
| Check module completion status | `architecture.md` | §3.2 has detailed status table |
| Build/tooling config | `mudlet-snd/nx.json`, `mudlet-snd/package.json` | Nx + pnpm, TS tooling for Lua project |
| Planning/tickets | `thoughts/tickets/`, `thoughts/plans/` | Implementation plans and feature tickets |
| Research analysis | Root `*.md` files | Porting analysis, architecture deep-dive |

## Code Style
- **Language**: Lua (Mudlet scripting) with TypeScript build tooling
- **Formatting**: Prettier, single quotes (`"singleQuote": true`)
- **Namespace**: Global `SnD` table — all modules attach as `SnD.ModuleName`
- **Naming**: PascalCase modules (`SnD.Hunt`), camelCase functions (`SnD.Hunt.execute`)
- **Module loading**: `dofile('module.lua')` — NOT `require()`
- **Compatibility**: Every Mudlet API call needs a mock fallback (see `core.lua` pattern)
- **File structure**: One `.lua` file per feature module in `src/`

## Anti-Patterns
- **Do NOT edit `mudlet-snd-flattened/`** — it's a stale reference copy
- **Do NOT edit `snd-original/`** — read-only reference material
- **Never call Mudlet APIs without mock guards** — code must run outside Mudlet runtime
- `aliases.lua` has duplicate content (lines 1-14 repeated at 15-27) — fix when touching

## Architecture
Event-driven: `raiseEvent()` / `registerAnonymousEventHandler()` for module communication.
```
Aliases → Core Logic (hunt/campaign/mapper/qw) → Database
                       ↕ events
              GUI (gui/buttons/campaign_gui)
                       ↑
                   GMCP (gmcp/realtime)
```

## Project Status
4/15 modules complete (core, database, mock_data, tests). 10/15 skeleton. 1/15 partial.
Original Crowley version: 10,110 lines, 360 functions, 95 aliases, 164 triggers.

## Notes
- `mudlet-snd/` is a **git submodule** — commits inside require separate push
- `project.json` at monorepo root contains tsconfig compiler options (not typical Nx project config)
- Database uses Mudlet's built-in `db:create()` SQLite wrapper
- Test files use print-based validation, not a formal test framework