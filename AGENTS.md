# Mudlet Search and Destroy - Agent Guidelines

## Build Commands
- **Build**: `nx build` or `pnpm exec nx build`
- **Test**: `nx test` or `pnpm exec nx test` (run single test: `nx test --testNamePattern="testName"`)
- **Lint**: `nx lint` or `prettier --check .`
- **Typecheck**: `nx typecheck` or `pnpm exec nx typecheck`
- **All checks**: `pnpm exec nx run-many -t lint test build typecheck`

## Code Style Guidelines
- **Language**: Lua (Mudlet scripting) with TypeScript configuration for build tooling
- **Formatting**: Prettier with single quotes (`"singleQuote": true`)
- **Namespace**: Use global `SnD` namespace for all modules
- **Module loading**: Use `dofile('module.lua')` pattern
- **Compatibility**: Include Mudlet function compatibility layers with mock fallbacks
- **Error handling**: Use print statements for mock/debug output, proper event handling for Mudlet functions
- **Naming**: PascalCase for modules (SnD.ModuleName), camelCase for functions and variables
- **File structure**: Each major feature in separate .lua file under src/
- **Testing**: Comprehensive test files with descriptive print statements for validation