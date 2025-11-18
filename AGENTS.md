# Nx Monorepo - Mudlet Search and Destroy

## Build Commands
- Build: `nx build <project>` or `nx run-many --target=build --all`
- Typecheck: `nx typecheck <project>` or `nx run-many --target=typecheck --all`
- Lint: `prettier --check .` (no nx lint configured)
- Format: `prettier --write .`
- Test: `nx test <project>` (when projects exist)
- CI: `pnpm exec nx run-many -t lint test build typecheck`

## Code Style Guidelines
- Use single quotes for strings (Prettier config)
- TypeScript strict mode with comprehensive type checking
- ES2022 target with Node.js next module resolution
- No unused locals, no implicit returns, strict null checks
- Use `@mudlet-snd/source` custom condition for internal imports
- Follow Nx monorepo patterns for library organization
- Prefer explicit imports over import helpers
- Use Nx CLI for all tasks instead of direct tool calls
