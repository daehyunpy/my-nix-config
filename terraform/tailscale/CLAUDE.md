# Tailscale Tailnet Management

Read the [shared Terraform workflow](../CLAUDE.md) for reviewed-plan approval, verification, backups, and state handoff. Run every command below from the repository root in the checkout holding this module's authoritative state.

This module owns the complete tailnet policy, DNS, device key-expiry settings, and approved subnet/exit routes. It does not manage tags, install clients, or change daemon preferences. Shared Home Manager tooling and Nix-managed client/services remain deferred in the [design spec](../../docs/superpowers/specs/2026-10-18-tailscale-management-design.md); the [implementation plan](../../docs/superpowers/plans/2026-10-20-tailscale-management.md) records completed work and deferred live gates. Use the native OpenTofu CLI; custom Python helpers remain deferred.

## CLI and credential-free checks

Use OpenTofu 1.13.1 from [.opentofu-version](.opentofu-version) and the committed provider lock. CI runs these checks without tailnet credentials, authenticated policy validation, plan, or apply:

```sh
tofu -chdir=terraform/tailscale fmt -check
tofu -chdir=terraform/tailscale init -backend=false -input=false -lockfile=readonly
tofu -chdir=terraform/tailscale validate
```

## Credentials and state

The provider pins the inventoried tailnet in `main.tf`. Supply scoped credentials only through `TAILSCALE_OAUTH_CLIENT_ID` and `TAILSCALE_OAUTH_CLIENT_SECRET`; any `TAILSCALE_TAILNET` value must match it. Keep operator secrets outside Git and the Nix store in a mode-0600 private file. The repository's `.env.example` contains empty names only.

Use the default local backend: no explicit backend declaration or custom location. The authoritative state is `terraform/tailscale/terraform.tfstate` in the active operator checkout. OpenTofu uses OS locking for that file; temporary `.terraform.tfstate.lock.info` metadata is ignored, not a permanent lock to commit. Backend selection is deferred to `BACKLOG.md` (INFRA-6); no remote backend, host, or custom state path is selected. No state or credentials were transferred to Thales.

## Saved-plan commands

With credentials loaded and the authoritative state located, initialize and create the private artifact for the shared review gate:

```sh
umask 077
tofu -chdir=terraform/tailscale init -input=false -lockfile=readonly
plan_dir="$(mktemp -d)"
tofu -chdir=terraform/tailscale plan -input=false -lock=true -out="$plan_dir/tailscale.tfplan"
tofu -chdir=terraform/tailscale show -no-color "$plan_dir/tailscale.tfplan"
```

Stop for approval of this saved plan. After approval and the private backup below, apply it as a separate operation, retaining the same `plan_dir`:

```sh
tofu -chdir=terraform/tailscale apply -input=false -lock=true "$plan_dir/tailscale.tfplan"
```

## Provider-specific verification

Compare the effective API/CLI policy, DNS, approved routes, key expiry, device ownership, and identities against the approved changes and preservation requirements below. Confirm all eight resource bindings in refreshed state, then run:

```sh
tofu -chdir=terraform/tailscale plan -refresh=true -input=false -detailed-exitcode
```

The shared completion gate requires exit `0` with no drift. Policy validation does not prove an actual SSH session or working client daemon; host/runtime proof remains a separate deferred phase.

## Backup and recovery commands

Use this procedure for the shared before/after state-mutation backup requirement:

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

For recovery, restore a verified private backup to the default state location with matching source and credentials before reviewing a plan. Follow the [shared handoff procedure](../CLAUDE.md#worktree-state-handoff) before retiring an operator checkout; this module requires all eight bindings and zero drift in the retained checkout.

## Adoption and ownership

`imports.tf` declares eight existing objects. Import blocks share the device/router maps with resources, so instance membership and IDs have one source. Looped imports require OpenTofu/Terraform 1.7 or newer; use the pinned OpenTofu version above.

| Resource | Import identity |
| --- | --- |
| `tailscale_acl.tailnet` | `acl` |
| `tailscale_dns_configuration.tailnet` | `dns_configuration` |
| `tailscale_device_key.managed` — Apollo, Muse, Thales, Poseidon | Current node IDs in `local.devices` |
| `tailscale_device_subnet_routes.routers` — Thales, Poseidon | Current node IDs for `local.router_routes` members |

A deliberately fresh adoption should plan eight imports, no creates/deletes, and any separately reviewed configuration updates. Existing state skips imports for tracked addresses. Keep import blocks as adoption records. Applying an import plan also applies its configuration updates; review the whole artifact.

The old Muse-tag proposal is superseded. Older state may contain obsolete tag bindings or Thales's historical device ID and `192.168.68.0/24` route. Reconcile those bindings only after a fresh inventory and private backup, using the current node ID and `192.168.2.0/24` subnet in configuration. Do not apply tag-destruction or missing-node creation plans to repair bookkeeping.

To release an object without changing its live setting, follow the shared ownership-removal procedure. For example, after removing Apollo from `local.devices` and therefore both resource/import membership, forget its binding:

```sh
tofu -chdir=terraform/tailscale state rm 'tailscale_device_key.managed["apollo"]'
```

Review a fresh plan: the released instance must not be imported, created, updated, or destroyed. Removing state alone re-adopts or recreates an object while source remains; removing source alone can propose destruction. Device-key deletion re-enables expiry and route-resource deletion clears approvals. Do not use `tofu destroy` to relinquish management or apply unrelated changes during release.

## Policy and host preservation

- Keep `acls` and `grants` omitted; an empty list would replace the existing default network access.
- Use only Cloudflare's logical nameserver `1.1.1.1`, with `use_with_exit_node = false`. Preserve MagicDNS, local DNS override disabled, and no extra search paths. Clients still prefer local DNS with override disabled; console expansion of public-provider address groups is not a reason to add another resolver.
- `tailscale_dns_configuration` is alpha in the pinned provider. Keep the dependency lock and review upgrades deliberately.
- SSH policy accepts member-to-self access as `autogroup:nonroot` or `root`, without periodic browser checks. It applies to members' own devices, not only Muse or only `daehyun`. Omit comments and unused empty `tagOwners`/`sshTests` fields.
- Validate HuJSON through Tailscale's read-only `POST /api/v2/tailnet/{tailnet}/acl/validate` endpoint. Temporary validator-only SSH tests can exercise ownership behavior without editing policy source. Inspect `data[].errors` as well as HTTP status: failed tests can return HTTP 200. Do not assume the pinned provider's plan runs these tests.
- Preserve the member Funnel capability without publishing a service, plus existing device ownership, identities, routes, DNS, and expiry. No tag transition or credential expansion is in scope.
- Leave host activation unchanged: Apollo's App Store client and encrypted state, Thales's Homebrew daemon, and Poseidon's Fedora 43 WSL vendor service remain intact. SSH enablement, route advertisements, exit-node activation, and Nix client/service management stay deferred.
