# TODO

- [ ] Make project-local OMP plugin installation reproducible.
  - [x] Declare PR Review Toolkit and Context7 in `.claude/settings.json` and install them with the Claude CLI at project scope.
  - [x] Share `/nix-check` from `.claude/commands` and verify discovery in Claude Code and OMP.
  - [x] Remove duplicate OMP installations of the shared plugins and keep generated registries/caches out of Git.
  - [ ] Provide one explicit setup command, including the remaining Superpowers OMP bootstrap requirement.
  - [ ] Resolve cached plugin version selection and verify setup from a fresh checkout, including project isolation.
  - [ ] Recheck native OMP or extension support before implementing a custom solution; do not invent unsupported `config.yml` keys or require a Nix launcher.

- [ ] Improve `README.md` and clarify its responsibilities versus `CLAUDE.md`.
  - Define `README.md` as human-facing project documentation: overview, prerequisites, setup, usage, and maintenance.
  - Define `CLAUDE.md` as agent-facing instructions: repository conventions, constraints, and verification expectations.
  - Remove duplicated or conflicting guidance and cross-reference shared information instead of maintaining two copies.
