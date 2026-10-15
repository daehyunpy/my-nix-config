# TODO

- [ ] Make project-local OMP plugin installation reproducible.
  - Track a plugin list and provide one explicit setup command using OMP's existing marketplace installer.
  - Include Superpowers and PR Review Toolkit; keep Context7 in `.omp/mcp.json`.
  - Keep generated registries, caches, and machine-specific paths out of Git.
  - Verify setup from a fresh checkout, including plugin discovery and project isolation.
  - Recheck native OMP or extension support before implementing a custom solution; do not invent unsupported `config.yml` keys or require a Nix launcher.

- [ ] Improve `README.md` and clarify its responsibilities versus `CLAUDE.md`.
  - Define `README.md` as human-facing project documentation: overview, prerequisites, setup, usage, and maintenance.
  - Define `CLAUDE.md` as agent-facing instructions: repository conventions, constraints, and verification expectations.
  - Remove duplicated or conflicting guidance and cross-reference shared information instead of maintaining two copies.
