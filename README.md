# my-nix-config

Maintain a single source of truth for my macOS, Linux, and WSL environments: packages, applications, dotfiles, and machine-specific settings. Make environments reproducible and straightforward to rebuild, share configuration where practical, and keep platform-specific exceptions explicit. Prefer declarative changes over undocumented manual setup; keep secrets outside the repository.

WSL uses the Linux Home Manager configuration; Windows host settings are not managed here. Keep the checkout at `~/.config/nix`.

Prefer Homebrew for macOS applications and platform-specific packages. Use Nix for core CLI tools and services shared across macOS, Linux, and WSL; share package declarations while keeping platform-specific service management explicit.

- `home.nix`, `packages.nix`: shared Home Manager configuration and packages.
- `darwin/`, `linux/`: platform and machine configuration.
- `home-files/`: managed dotfiles.
- `terraform/`: Terraform-compatible infrastructure configuration, executed with OpenTofu.

## Setup

Install [Nix](https://nixos.org/download/), then enable flakes:

```sh
mkdir -p ~/.config/nix
printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### macOS

```sh
# Bootstrap nix-darwin
nix run nix-darwin -- switch --flake ~/.config/nix/darwin

# Apply changes
darwin-rebuild switch --flake ~/.config/nix/darwin
```

Homebrew formulae, casks, and App Store apps are declared in `darwin/`. Unrestricted passwordless sudo for the admin group is intentional.

The Dock pins `/System/Applications/Siri AI.app` for browsing Siri conversations, not the CoreServices Siri assistant.

### Linux

Replace `username@hostname` with a configuration from `linux/flake.nix`:

```sh
# Bootstrap Home Manager
nix run home-manager -- switch --flake ~/.config/nix/linux#username@hostname

# Apply changes
home-manager switch --flake ~/.config/nix/linux#username@hostname
```

To use the Nix-managed Fish as your login shell:

```sh
fish_path="$HOME/.nix-profile/bin/fish"
if ! grep -Fxq "$fish_path" /etc/shells; then
  printf '%s\n' "$fish_path" | sudo tee -a /etc/shells
fi
sudo chsh -s "$fish_path" "$USER"
```

Start a new login session after activation; reconnect remote editors to reload the shell.

## Tailscale tailnet management

`terraform/tailscale/` owns the complete tailnet policy, DNS, device key-expiry settings, and approved subnet/exit routes. It does not manage tags, install clients, or change daemon preferences. Shared Home Manager tooling and generic Nix-managed services remain a deferred phase in the [design spec](docs/superpowers/specs/2026-10-18-tailscale-management-design.md); their implementation is stashed. Existing Home Manager names and services remain unchanged.

**The reviewed Terraform application is complete.** It changed only policy formatting/unused fields; host activation and additional changes remain outside that authorization. Use the pinned OpenTofu version in `.opentofu-version` and the committed provider dependency lock:

```sh
tofu -chdir=terraform/tailscale fmt -check
tofu -chdir=terraform/tailscale init -backend=false -input=false -lockfile=readonly
tofu -chdir=terraform/tailscale validate
```

These checks need no tailnet credentials. CI runs them without plan, apply, or secrets.

### Credentials and default local state

Start with OpenTofu's default local backend: no explicit backend declaration or custom location. With `-chdir=terraform/tailscale`, the authoritative file is `terraform/tailscale/terraform.tfstate` in the active operator checkout.

Use one operator and one authoritative state file. Branches and worktrees do not isolate the live tailnet; do not keep independently active state copies for the same resources. Back up state before moving it to another checkout, and retire the former active copy after verification.

The provider pins the inventoried tailnet. Supply scoped credentials only through `TAILSCALE_OAUTH_CLIENT_ID` and `TAILSCALE_OAUTH_CLIENT_SECRET`; any `TAILSCALE_TAILNET` value must match that root. Keep operator secrets outside Git and the Nix store in a mode-0600 private file. `.env.example` contains empty names only.

Initialize the local working directory, then plan with credentials loaded into the environment:

```sh
umask 077
tofu -chdir=terraform/tailscale init -input=false -lockfile=readonly
tofu -chdir=terraform/tailscale plan -input=false -detailed-exitcode
```

Commit `.terraform.lock.hcl`: it pins provider versions and checksums, not state access. OpenTofu locks local state automatically using OS APIs; temporary `.terraform.tfstate.lock.info` metadata is gitignored. Do not create or commit a permanent state lock file. This lock coordinates the same local state file, not independent copies in other worktrees or hosts.

State, state backups, provider caches, saved plans, and secret variable files are gitignored. Backend selection is deferred to `BACKLOG.md` (INFRA-6) with all options open. No backend protocol, product, host, or custom state location is selected.

Exit 0 means no changes, 2 means proposed changes, and 1 means failure. Review each fresh plan before any separately authorized application. Eight existing resources are adopted. On 2026-11-08, the reviewed policy cleanup was applied with no SSH/Funnel behavior change; the post-apply plan exited 0 with no changes. DNS, route approvals, expiry, ownership, IDs, and addresses were verified unchanged. Thales's current device record and approved `192.168.2.0/24` subnet supersede its historical ID and `192.168.68.0/24` route.

The secondary DNS extension is declared but not yet applied: Cloudflare `1.1.1.1` plus Google `8.8.8.8`. Review a separate DNS-only plan before application; the earlier zero-drift result predates this extension.

The earlier Muse-tag proposal is superseded by the simpler user-selected policy. Local adoption state was backed up privately, obsolete tag bindings were forgotten without deleting remote resources, and Thales's key/route settings were imported against its current node ID. An operator with older state must reconcile those bindings after a fresh inventory and private backup; do not apply tag-destruction or missing-node creation plans to repair bookkeeping.

### Backups and recovery

Before and after every state-changing operation, save a versioned private backup outside the checkout:

```sh
set -eu
umask 077
backup_dir="$HOME/.config/tailscale-iac/backups/$(date -u +%Y-%m-%d)"
mkdir -p "$backup_dir"
backup=$(mktemp "$backup_dir/local-$(date -u +%H%M%S).XXXXXX")
tofu -chdir=terraform/tailscale state pull > "$backup"
jq -e '.lineage != null and .serial != null and .resources != null' "$backup" >/dev/null
printf 'Validated private backup: %s\n' "$backup"
```

Require successful state retrieval and valid JSON before treating the new file as a backup; keep earlier backups. If state is lost, first restore a recent private backup to the default `terraform/tailscale/terraform.tfstate` location in the intended operator checkout and review a plan with the matching source and credentials. Establish exclusive recovery ownership before any apply; do not run recovery and normal applies concurrently. Declarative imports are a recovery/adoption option after checking the current inventory, not permission to create replacement resources.

No state or credentials were transferred to Thales. Its earlier tool/worktree preparation did not establish a remote backend or state service.

### Adoption and ownership

`imports.tf` declares the eight existing objects to adopt. It shares the device and router maps with the resources, so identifiers and instance membership have one source. Looped imports require OpenTofu/Terraform 1.7 or newer; use the pinned OpenTofu 1.13.1.

| Managed resource | Import identity |
| --- | --- |
| `tailscale_acl.tailnet` | `acl` |
| `tailscale_dns_configuration.tailnet` | `dns_configuration` |
| `tailscale_device_key.managed` — Apollo, Muse, Thales, Poseidon | Current node IDs in `local.devices` |
| `tailscale_device_subnet_routes.routers` — Thales, Poseidon | Current node IDs for `local.router_routes` members |

A fresh state should plan eight imports, no creates/deletes, and any separately reviewed configuration updates. Existing state skips imports for addresses already tracked. Imports can stay as adoption records. The current fresh-state plan also includes the pending Google DNS update: applying an import plan applies its shown updates too, not just bookkeeping. Do not apply it without authorization for those changes.

### Stop managing without changing the live setting

1. Back up private state and record the live value.
2. Remove the resource instance **and its import membership/declaration** from source. Shared `for_each` entries can remove both together; retain any identity data still needed by other resources. Do not apply a destruction plan.
3. Forget the matching state address locally after making the corresponding configuration change. For example, after removing the non-router Apollo entry from `local.devices`:

   ```sh
   tofu -chdir=terraform/tailscale state rm 'tailscale_device_key.managed["apollo"]'
   ```

4. Review a fresh plan: the released instance must not be imported, created, updated, or destroyed. Do not apply unrelated changes as part of relinquishing ownership.

`state rm` alone is insufficient: leaving an import block re-adopts the object; leaving only the resource configuration proposes creation/update. Removing source alone can instead propose a destructive provider operation. Device-key deletion re-enables expiry and route-resource deletion clears approvals, so do not use `tofu destroy` to relinquish management.

### Policy and preservation

- Keep `acls` and `grants` omitted; an empty list would replace the existing default network access.
- Preserve MagicDNS, local DNS override disabled, and no extra search paths. Add Google `8.8.8.8` alongside Cloudflare `1.1.1.1` for provider redundancy, with exit-node DNS use disabled for both. This is not strict primary/secondary failover; either provider may receive queries. Clients still prefer local DNS because override remains disabled. Public-provider address groups expand automatically in the console.
- The provider marks `tailscale_dns_configuration` as alpha. Keep the dependency lock and review provider upgrades deliberately.
- The SSH policy accepts member-to-self access as `autogroup:nonroot` or `root`, without periodic browser checks. It applies to members' own devices, not only Muse or only `daehyun`. Comments and unused empty `tagOwners`/`sshTests` fields are omitted.
- Validate HuJSON through Tailscale's read-only `POST /api/v2/tailnet/{tailnet}/acl/validate` endpoint. Temporary validator-only SSH tests can exercise ownership behavior without changing the source. Inspect `data[].errors` as well as HTTP status; failed tests can return HTTP 200. Do not assume the pinned provider's plan runs these tests.
- Preserve the member Funnel capability without creating a published service, and preserve existing device ownership, identities, routes, DNS, and expiry. No credential expansion is needed for a tag transition because no transition is in scope.
- Validation proves policy evaluation, not an actual SSH session or working daemon. Host migration and network/runtime proof remain separate from this Terraform-only phase.

No host activation is part of this phase. Apollo's App Store client and encrypted state stay intact; Thales keeps its Homebrew daemon, and Poseidon keeps its Fedora 43 WSL vendor service. The [implementation plan](docs/superpowers/plans/2026-10-20-tailscale-management.md) records current checks and deferred live gates.

## Maintenance

- Update inputs: `nix flake update --flake darwin` or `nix flake update --flake linux`, then apply.
- Garbage collection runs weekly and removes unreferenced generations older than 30 days, making them unavailable for rollback.
- Approve trusted direnv configurations with `direnv allow`. `.env` is gitignored; see `.env.example`.

## Agent Workflows

Coding, validation, and agent/editor setup instructions live in [CLAUDE.md](CLAUDE.md). Agents perform repository changes and checks; system activation and other protected host changes require explicit user authorization.
