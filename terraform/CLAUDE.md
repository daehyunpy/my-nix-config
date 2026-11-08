# Terraform Workflow

Each configuration directory under `terraform/` is an independent OpenTofu root module; `terraform/` itself is not one. Use the module's CLI pin and committed provider lock. Keep infrastructure policy and device inventory authoritative in configuration.

Agents run the commands below from the repository root in the selected worktree. Follow the [repository authorization boundary](../CLAUDE.md#yolo-boundary); instructions and successful checks do not authorize remote changes.

## Tailscale tailnet management

`terraform/tailscale/` owns the complete tailnet policy, DNS, device key-expiry settings, and approved subnet/exit routes. It does not manage tags, install clients, or change daemon preferences. Shared Home Manager tooling and generic Nix-managed services remain a deferred phase in the [design spec](../docs/superpowers/specs/2026-10-18-tailscale-management-design.md); their implementation is stashed. Existing Home Manager names and services remain unchanged.

**The initial policy cleanup is complete.** It changed only policy formatting/unused fields. Further applications require their own reviewed plan and explicit authorization. Use the pinned OpenTofu version in `.opentofu-version` and the committed provider dependency lock:

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

The separately approved Google DNS extension was applied on 2026-11-08 and verified with API/state checks and a zero-change plan. The user then requested only Cloudflare `1.1.1.1`; source now excludes Google, but the new removal plan requires separate approval. Do not report live DNS as Cloudflare-only until that plan is applied and verified.

The earlier Muse-tag proposal is superseded by the simpler user-selected policy. Local adoption state was backed up privately, obsolete tag bindings were forgotten without deleting remote resources, and Thales's key/route settings were imported against its current node ID. An operator with older state must reconcile those bindings after a fresh inventory and private backup; do not apply tag-destruction or missing-node creation plans to repair bookkeeping.

### Manual OpenTofu workflow

Use the native OpenTofu CLI; custom Python helpers and their tests are deferred. After the credential-free checks and default-local initialization above, with scoped credentials in the environment, create and inspect a private saved plan:

```sh
umask 077
plan_dir="$(mktemp -d)"
tofu -chdir=terraform/tailscale plan -input=false -lock=true -out="$plan_dir/tailscale.tfplan"
tofu -chdir=terraform/tailscale show -no-color "$plan_dir/tailscale.tfplan"
```

Saved plans contain sensitive data. Keep this temporary directory private and never commit or share its contents; it is not a durable recovery backup. The state file remains in the module's default local location.

Present the saved plan's proposed actions and risks to the user, then stop for explicit approval of that reviewed plan. A request to change a setting or a successful plan is not approval to apply an unseen plan. Never combine planning and applying in the same unattended tool call.

**Applying a saved plan skips OpenTofu's confirmation prompt.** Only after approval of this exact plan and a private off-checkout state backup, run the following as a separate operation:

```sh
tofu -chdir=terraform/tailscale apply -input=false -lock=true "$plan_dir/tailscale.tfplan"
```

Saved plans retain their original inputs; they do not follow later source edits. Replan and obtain fresh approval after changing source, policy, provider/CLI pins, variable inputs, or observing drift. OpenTofu checks for stale state and locks the authoritative state file; do not disable locking. Follow the backup procedure below before and after every attempted apply, including failures that may have partially changed resources, and remove private plan artifacts after use.

`prevent_destroy` does not stop in-place updates. CI runs credential-free formatting and schema validation, not authenticated policy validation, apply, or host-behavior checks. Tailscale SSH enablement, route advertisements, exit-node activation, and Nix client/service management remain deferred. Every further resolver change requires approval of its reviewed saved plan.

### Verify an authorized apply

An apply success message alone is not completion:

1. Query the Tailscale API or CLI and compare the effective remote settings with the approved changes, including policy, DNS, route approvals, expiry, and identities that must remain unchanged.
2. Inspect refreshed OpenTofu state to confirm the intended resource bindings and managed values without printing secrets.
3. Run a fresh authenticated plan with refresh enabled:

   ```sh
   tofu -chdir=terraform/tailscale plan -refresh=true -input=false -detailed-exitcode
   ```

Require exit 0 with no drift after applying the approved changes. A mismatch or verification error means the operation is incomplete: report expected versus observed settings and obtain approval of a new reviewed plan before any corrective apply. This is a post-apply gate, not permission to apply a newly requested configuration change without review.

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

A fresh state should plan eight imports, no creates/deletes, and any separately reviewed configuration updates. Existing state skips imports for addresses already tracked. Imports can stay as adoption records. Applying an import plan also applies its shown configuration updates, not just bookkeeping; obtain approval for the entire plan.

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
- Use only Cloudflare's logical nameserver `1.1.1.1`, with `use_with_exit_node = false`. Preserve MagicDNS, local DNS override disabled, and no extra search paths. Clients still prefer local DNS because override remains disabled. Public-provider address groups expand automatically in the console; do not add Google or another provider without a newly reviewed and approved change.
- The provider marks `tailscale_dns_configuration` as alpha. Keep the dependency lock and review provider upgrades deliberately.
- The SSH policy accepts member-to-self access as `autogroup:nonroot` or `root`, without periodic browser checks. It applies to members' own devices, not only Muse or only `daehyun`. Comments and unused empty `tagOwners`/`sshTests` fields are omitted.
- Validate HuJSON through Tailscale's read-only `POST /api/v2/tailnet/{tailnet}/acl/validate` endpoint. Temporary validator-only SSH tests can exercise ownership behavior without changing the source. Inspect `data[].errors` as well as HTTP status; failed tests can return HTTP 200. Do not assume the pinned provider's plan runs these tests.
- Preserve the member Funnel capability without creating a published service, and preserve existing device ownership, identities, routes, DNS, and expiry. No credential expansion is needed for a tag transition because no transition is in scope.
- Validation proves policy evaluation, not an actual SSH session or working daemon. Host migration and network/runtime proof remain separate from this Terraform-only phase.

No host activation is part of this phase. Apollo's App Store client and encrypted state stay intact; Thales keeps its Homebrew daemon, and Poseidon keeps its Fedora 43 WSL vendor service. The [implementation plan](../docs/superpowers/plans/2026-10-20-tailscale-management.md) records current checks and deferred live gates.

