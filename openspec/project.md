# Project Context

## Purpose
Declarative, reproducible macOS and Linux system configuration using Nix and the NixOS ecosystem. This project manages:
- System-level packages and settings via nix-darwin (macOS)
- User-level environment and dotfiles via home-manager
- Multi-machine configurations with platform-specific customizations
- Development tool integrations (editors, terminals, shells)
- Encrypted secrets management with git-crypt

Goals:
- Reproducible development environments across multiple machines
- Version-controlled system configuration
- Seamless synchronization of tools and settings
- Support for remote development workflows

## Tech Stack

### Nix Ecosystem
- **nix-darwin** (25.11): macOS system configuration framework
- **home-manager** (25.11): User-level package and dotfiles management
- **nixpkgs** (stable 25.11 + unstable overlay): Package repository
- **nix-homebrew**: Declarative Homebrew integration for macOS

### Development Tools & Languages
- **Languages**: Nix, Python (Poetry/uv), Node.js, Bun, Java (Temurin JRE)
- **Editors**: Cursor (primary), Zed (Rust/AI), Helix (CLI), VS Code
- **Terminal**: WezTerm, Tmux, Fish (default shell), Zsh
- **AI Assistants**: Claude Code, Cursor AI, Gemini Code Assist

### DevOps & Infrastructure
- **Containers**: Docker, Podman, lazydocker
- **Kubernetes**: kubectl, kubectx, helm, kustomize, k9s
- **Cloud**: AWS CLI, Terraform (tenv)
- **VCS**: Git, git-crypt, git-lfs

### CLI Utilities
- **Search**: ripgrep, ripgrep-all, fzf, fd
- **Data**: DuckDB, jq, yq
- **LSPs**: nixd, nil (Nix), Ruff (Python)
- **Formatters**: nixfmt-rfc-style, Prettier, Ruff

### Specialized Tools
- **GIS**: QGIS, GDAL (morpheus machine)
- **Media**: Plex Media Server (thales machine)
- **LaTeX**: TeX Live distribution (morpheus machine)

## Project Conventions

### Code Style
- **Nix**: Use `nixfmt-rfc-style` formatter (RFC 166 style)
- **Python**: Ruff for linting and formatting, auto-format on save
- **JSON/YAML**: Prettier with default settings
- **Terraform**: Built-in formatter
- **Naming**: Lowercase with hyphens for Nix files (e.g., `brews.nix`, `mas.nix`)

### Architecture Patterns

#### Modular Configuration Layering
Three-tier hierarchy for maximum reusability:
```
Shared base (home.nix, packages.nix)
  ↓
Platform-specific (darwin/home.nix, linux/home.nix)
  ↓
Machine-specific overrides (in flake.nix)
```

#### Home-Manager File Management
- Use `mkOutOfStoreSymlink` for frequently-edited configs (Zed, Cursor, WezTerm, etc.)
- Store dotfiles in `home-files/` directory within repo
- Allows direct editing without Nix rebuilds

#### Multi-Machine Strategy
- **Darwin machines**: morpheus (GIS), apollo (dev), thales (media)
- **Linux machines**: octo60, octo61, octo62 (remote dev)
- Platform detection via `pkgs.stdenv.isDarwin` and `pkgs.stdenv.isLinux`

#### Package Management
- Stable packages from nixpkgs-25.11-darwin/nixpkgs-25.11
- Unstable packages via overlay when needed
- Homebrew integration for macOS-only GUI apps
- Mac App Store apps via `mas-apps.nix`

### Testing Strategy

#### OpenSpec Validation
- Strict validation for all change proposals: `openspec validate --strict --no-interactive`
- Three-stage workflow: Proposal → Implementation → Archive
- Specs stored in `openspec/specs/` with capability definitions
- Changes tracked in `openspec/changes/` with archiving by date

#### Configuration Validation
- Flake locks ensure dependency reproducibility (`flake.lock`)
- Test builds with: `darwin-rebuild check` or `home-manager build`
- State version tracking (home 25.11, system 5) for safe migrations
- Overlays validated against both stable and unstable channels

#### Pre-commit Practices
- Changes are incremental and focused (one feature/fix per commit)
- Co-authoring with AI assistants credited in commits
- No destructive operations without explicit backups

### Git Workflow

#### Branching Strategy
- **Main branch**: Direct commits for small, focused changes
- **Feature branches**: For experimental or breaking changes (implied by OpenSpec workflow)
- No formal PR process for personal configs, but OpenSpec provides approval gates

#### Commit Message Format
- Imperative mood: "Add X", "Update Y", "Remove Z"
- Descriptive paragraphs for complex changes
- Co-author credit: `Co-Authored-By: Claude <noreply@anthropic.com>`

#### Git Configuration
- **Diff algorithm**: histogram with rename and color-moved detection
- **Rebase defaults**: auto-squash, auto-stash, update-refs enabled
- **Rerere**: Reuse recorded resolutions for conflicts
- **Fetch**: Prune deleted branches, fetch all remotes
- **Merge conflict style**: zdiff3 (three-way diff)
- **Default branch**: main

#### Security
- Encrypted secrets via git-crypt (`secret-envs.json`)
- Git-LFS for large files
- Sensitive configs never committed in plaintext

## Domain Context

### Remote Development
- SSH access to three Linux machines (octo60/61/62) from macOS
- Zed and Cursor configured with remote SSH connections
- Multiple user accounts supported (dhyou, trino)
- Conda environments per machine (base, octo60, octo61, octo62)

### GIS and Spatial Data (morpheus machine)
- QGIS for spatial analysis
- GDAL for geospatial data processing
- LaTeX for academic/technical documentation

### Media Server (thales machine)
- Plex Media Server for media streaming
- Transmission for torrent management

### AI-Assisted Development
- Claude Code for Nix and general development
- Cursor AI for inline code suggestions
- Zed with Claude Sonnet 4.5 integration
- OpenSpec for specification-driven development

## Important Constraints

### Platform Limitations
- **macOS only**: nix-darwin, Homebrew Casks, Mac App Store apps
- **Architecture**: Primary support for aarch64-darwin (Apple Silicon)
- **Rosetta 2**: Required for some x86_64 Homebrew packages

### Nix Constraints
- Home-manager state version must match nixpkgs channel (25.11)
- Cannot downgrade state versions once set
- Flake inputs must be updated together to avoid version conflicts
- Some GUI apps require Homebrew (not available in nixpkgs)

### Security Constraints
- Sudo passwordless for admin group (convenience over strict security)
- Git-crypt key required for accessing encrypted files
- SSH keys managed outside of Nix store

### Configuration Constraints
- Dotfiles in `home-files/` must exist before first build
- Out-of-store symlinks require absolute paths resolved at build time
- Some macOS apps require manual login after installation

## External Dependencies

### Nix Infrastructure
- **nixpkgs**: Official Nix package repository (github:NixOS/nixpkgs)
- **nix-darwin**: macOS system framework (github:LnL7/nix-darwin)
- **home-manager**: User environment manager (github:nix-community/home-manager)
- **nix-homebrew**: Homebrew integration (github:zhaofengli/nix-homebrew)

### Package Registries
- **Homebrew**: macOS package manager (brew.sh)
- **Mac App Store**: Official Apple app distribution
- **npm/pnpm**: JavaScript package registries
- **Conda**: Python package manager (conda-forge, defaults)
- **PyPI**: Python packages via Poetry/uv

### Remote Services
- **GitHub**: Version control hosting
- **Anthropic**: Claude AI API (for Claude Code, Cursor AI)
- **Google**: Gemini API (for Gemini Code Assist)
- **Tailscale**: Mesh VPN for remote access
- **Proton**: Email and cloud storage

### Development Infrastructure
- **SSH servers**: octo60, octo61, octo62 (remote Linux machines)
- **AWS**: Cloud infrastructure (via AWS CLI)
- **Kubernetes clusters**: Managed via kubectl/helm/k9s
- **Docker/Podman**: Container runtimes

### AI and Automation
- **OpenSpec**: Specification validation framework
- **Claude Code**: AI coding assistant
- **Cursor**: AI-powered code editor
- **Zed**: Collaborative editor with AI
