# Tailscale tailnet management and deferred Nix integration

## Status and execution boundary

**Terraform phase: implemented; secondary DNS pending application.** `terraform/tailscale/` manages eight resources: the complete policy, DNS configuration, four device-key expiry settings, and the two routers' approved routes. Existing resources were imported, not recreated. The earlier policy-only application completed with a zero-change plan. The follow-on DNS extension adds Google alongside Cloudflare and must be planned separately; it has not been applied. Nix-based client/service management remains deferred, retained below and in the stash named `WIP: Tailscale Nix configuration (not applied)`.

The user subsequently authorized applying the reviewed Terraform root. On 2026-11-08, its saved plan changed only `tailscale_acl.tailnet` to remove comments/unused fields, preserving SSH/Funnel behavior. The post-apply plan exited 0 with no changes; DNS, routes, expiry, ownership, tags, IDs, and addresses were verified unchanged. Pre/post state and API snapshots were backed up privately outside Git. This completed application does not authorize future unrelated changes, host activation, client replacement, enrollment, tags, or new/expanded credentials.

The user selected the simpler ownership-based SSH policy supplied in the conversation. It supersedes the earlier Muse-specific tagged design. Do not implement tag ownership transitions, Muse-only selectors, or personal check-mode rules from that earlier proposal.

## Goal and ownership boundaries

Manage existing tailnet resources as code without changing the current setup. Terraform owns control-plane policy, DNS, key-expiry settings, and approved routes. Existing daemons continue to own host preferences and route advertisements. A later Nix phase will adopt user tooling and privileged services independently.

Home Manager manages user tooling, not the root daemon. Neither the current Terraform root nor future Home Manager activation may install a competing daemon, run privileged activation hooks, or reenroll devices.

## Implemented phase: Terraform/OpenTofu

### Repository layout

```text
terraform/tailscale/
  .opentofu-version       OpenTofu CLI version: 1.13.1
  .terraform.lock.hcl      Provider dependency lock; version-controlled
  versions.tf             Official tailscale/tailscale provider ~> 0.29.2
  main.tf                 Explicit tailnet selection and complete policy ownership
  policy.hujson           User-selected ownership-based SSH and Funnel policy
  dns.tf                  One authoritative DNS configuration resource
  devices.tf              Existing device expiry and approved router routes
  imports.tf              Declarative adoption of the eight existing objects
```

`terraform/` names the configuration format and ecosystem clearly; OpenTofu is the execution CLI. Do not retain a second active root under `infra/` or add a deployment framework.

The earlier root rename moved local state without changing resource addresses. Keep the authoritative state with the active operator checkout when source moves between worktrees, after a private backup and verification. Do not create independent active state or reimport merely because the source directory changed.

### Authoritative inventory and preservation

Fresh read-only API inspection supersedes the original Cua baseline where they differ:

| Device | Current node ID | Tailscale IPv4 | Key expiry |
| --- | --- | --- | --- |
| Apollo | `nMzngfCre621CNTRL` | `100.73.130.74` | Enabled |
| Thales | `nhesn3Xjj111CNTRL` | `100.76.180.59` | Disabled |
| Poseidon | `npByKx79tM11CNTRL` | `100.68.77.38` | Disabled |
| Muse | `n3u5ATYqT411CNTRL` | `100.115.105.38` | Enabled |

All four inspected records are user-owned under the existing account and have no tags. Do not use matching hostnames alone as permission to replace device identities; adopt the inspected existing record. The earlier Thales ID `nrGyKDY9Dv11CNTRL`, IP `100.94.134.124`, and `192.168.68.0/24` subnet are historical, not values to restore.

- Thales's current advertised and enabled routes are `192.168.2.0/24`, `0.0.0.0/0`, and `::/0`.
- Preserve Poseidon's enabled exit routes `0.0.0.0/0` and `::/0`.
- Preserve each device's existing key expiry; no device replacement, reenrollment, ownership transition, or expiry-policy change.
- Manage eight existing resources: one policy, one DNS configuration, four device-key settings, and two route-approval collections. Do not manage device tags in this phase.
- Use `prevent_destroy` on adopted resources. This does not prevent destructive edits within a whole-policy or collection-valued resource; inspect the actual diff.

### Policy

`policy.hujson` is the full user-selected document, not a generated fragment:

- Omit unused `tagOwners`; no purpose-based tags are introduced.
- One SSH rule uses `action: accept`, `src: autogroup:member`, `dst: autogroup:self`, and users `autogroup:nonroot` plus `root`.
- Members may SSH without a periodic browser check to devices they own, including as root. This is intentionally broader than Muse-only access; it does not authorize access to another member's devices through `autogroup:self`.
- Preserve the existing Funnel node attribute for `autogroup:member`. Capability permission is not proof of a published Funnel service; do not create one.
- Omit unused `sshTests`. Use temporary validator-only tests for smoke verification rather than adding source policy tests.
- Omit `acls` and `grants` to preserve current default network access. Do not insert empty lists, convert policy styles, or infer narrower network rules from the SSH rule.
- Keep the policy concise, without explanatory comments or empty fields. The resource owns the entire document; fresh exports and plan review must detect behavioral changes rather than overwriting them blindly.

The earlier merged tagged policy was applied before the intervening no-apply instruction. A later read-only export established the simpler user-selected policy already live, and the subsequently authorized application cleaned its comments/unused fields only. Neither application assigned tags or migrated daemons. Do not restore the superseded tagged design.

### DNS

Use `tailscale_dns_configuration`, not overlapping legacy DNS resources:

- MagicDNS enabled; tailnet suffix `dingo-ratio.ts.net` unchanged.
- Local DNS override disabled; no extra search paths.
- Preserve Cloudflare's logical nameserver `1.1.1.1` and add Google's logical nameserver `8.8.8.8` for independent-provider redundancy. Both use `use_with_exit_node = false`.
- The GUI expands known public providers to their address groups; do not declare each expanded address as a separate resolver.
- “Secondary” means an additional resolver, not guaranteed ordered failover: clients may query multiple resolvers or choose by performance. DNS queries may reach either provider. With local override disabled, clients continue to prefer their local DNS configuration.
- Do not alter HTTPS provisioning, split DNS, or individual clients' DNS-acceptance preferences.

### Credentials and state

Pin the provider to inventoried tailnet `TByk7otHmv11CNTRL`. Credentials come only from standard `TAILSCALE_OAUTH_CLIENT_ID` and `TAILSCALE_OAUTH_CLIENT_SECRET` environment variables. Any `TAILSCALE_TAILNET` environment value must match the pinned root, not redirect it. Keep `.env.example` values empty.

Secrets stay outside Git and the Nix store in a mode-0600 private operator file, supplied through standard provider environment variables. Never print credentials, place them in Terraform variables, or create enrollment keys or broader scopes.

Start with the default local backend, without a backend block or custom location. With `-chdir=terraform/tailscale`, state is `terraform/tailscale/terraform.tfstate` in the active operator checkout. Use the default workspace and one operator/authoritative file. OS-backed locking protects that file, not independent state copies on different hosts or worktrees.

Ignore state, backups, caches, saved plans, overrides, and credential-bearing variable files; retain the provider dependency lock in Git. Back up before and after state changes to versioned mode-0600 files outside the checkout. Moving the active file between checkouts must preserve its lineage and resource bindings and retire the former active copy.

If state is lost, restore a recent private backup to the default location in the intended operator checkout, initialize the matching source, and review a plan with the private credential. Establish exclusive recovery ownership before any apply; never run recovery and normal applies concurrently.

Backend selection is a backlog task in `BACKLOG.md` (INFRA-6), with all storage/execution options open. No protocol, product, host, or custom state location is selected. The abandoned Thales preparation did not transfer state or credentials or start a backend service.

Keep declarative imports for policy (`acl`), aggregate DNS (`dns_configuration`), all four key settings, and both router approvals. Import loops use the same device/router maps as the resource declarations, with current node IDs. Require at least OpenTofu/Terraform 1.7 for looped imports and retain the tested OpenTofu 1.13.1 pin. Existing state must not re-import tracked addresses; fresh state must propose imports rather than creates. Applying an import plan also applies any shown configuration updates, so the pending secondary DNS change still requires separate authorization.

Relinquishing ownership is a coordinated source-and-state operation: back up state and live settings, remove the desired resource instance and its import entry/member, then forget its state binding before applying anything. Retain identities still referenced by other resources. Review a plan proving the released address is neither re-imported nor created/updated/destroyed. `state rm` alone permits re-adoption/recreation; source removal alone can plan destructive provider deletion. Do not use `destroy` to stop managing expiry or routes.

For this scope change, forget the three obsolete tag bindings from local state without invoking provider deletion. The inspected devices have no tags, and the new source must not propose tag removal. Back up state before forgetting stale Thales key/route bindings and importing those settings against its current node ID. Imports read the tailnet; they do not create or replace devices. If an operation fails, retain the private backup and stop before planning against incomplete adoption.

### Guarded manual apply

Use `terraform/tailscale/workflow.py` for normal manual plans and separately authorized applies. Keep default local state, credential-free CI, and all host/Nix activation deferrals unchanged.

- `plan` requires the existing authoritative default-workspace state and saves a private plan plus review metadata under `.terraform/reviewed-plans/`. Bind the artifact to its generating checkout, SHA-256, and the root's Terraform/OpenTofu configuration, variable files, HuJSON policy, provider lock, and CLI pin.
- `apply PLAN` accepts only an artifact generated in this checkout. Refuse changed plan bytes, changed source inputs, deletion/replacement actions, missing local state, and noninteractive input/output.
- Copy the plan into a private temporary directory, inspect its actual pinned tailnet, display that exact snapshot, and require the typed tailnet plus plan digest. Recheck source/artifact integrity after confirmation, then apply only the reviewed snapshot with OpenTofu's state lock enabled. Never generate a replacement plan during apply or offer a noninteractive approval flag.
- Follow the existing private before/after backup procedure. A saved plan is sensitive, is not an off-checkout recovery backup, and contains its original planning inputs. Replan after changing inputs or observing drift; OpenTofu still rejects stale state.
- These are accidental-apply safeguards, not a permission boundary: a holder of write credentials can bypass the helper. `prevent_destroy` does not block in-place updates. CI checks syntax/provider schema, not live policy or host behavior.

### Verification and current acceptance

From the repository root:

```sh
tofu -chdir=terraform/tailscale fmt -check
tofu -chdir=terraform/tailscale init -backend=false -input=false -lockfile=readonly
tofu -chdir=terraform/tailscale validate
```

- CI adds credential-free Terraform formatting, locked-provider initialization, configuration validation, and manual-workflow safety tests. It does not run authenticated plans, policy validation, or applies. Existing Nix evaluation jobs remain unchanged; generic CI refactoring and repository-wide agent/worktree policies are separate changes. No deferred Nix Tailscale output or nested agent-policy file is introduced.
- Validate the actual HuJSON through Tailscale's read-only `POST /api/v2/tailnet/{tailnet}/acl/validate` endpoint. Check the body as well as HTTP status: failed SSH tests can return HTTP 200 with `data[].errors`.
- Submit temporary owner-based acceptance tests for `daehyun` and `root` to current Thales/Poseidon. Remove the SSH rule only in an in-memory negative control and confirm those tests fail. Neither probe writes the live policy or adds source tests.
- After any separately authorized saved-plan application, run an authenticated read-only `plan -input=false -detailed-exitcode` and require exit 0 with no changes. The 2026-11-08 cleanup application met this criterion and preserved the inventoried control-plane settings; it did not enable host-side services or add secondary DNS.
- Confirm eight adopted resource addresses remain in local state, and the current Thales node/route settings are used. Do not log private state contents.
- From fresh state, declarative imports must cover exactly eight addresses with no creates/deletes. From a private copy of existing operator state, imports must be skipped and the plan must contain only the separately pending DNS update. Neither verification may change the actual operator state or live tailnet.
- Verify the active checkout's default state path, private-file exclusions, all eight adopted bindings, and a plan with no imports/creates/deletes and only the independently pending DNS update. Preserve a private backup before relocating the active local file.
- Validator tests prove policy evaluation, not actual Muse-originated SSH or daemon startup. No client migration or live traffic acceptance is claimed in this phase.

## Deferred phase: managing Tailscale through Nix

This remains an intended part of the repository design. It is not deleted, implemented, or required for Terraform-only delivery.

### Shared Home Manager tooling

Add `pkgs.tailscale` to the alphabetically sorted root `packages.nix`, consumed by the existing shared `home.nix`. Do not introduce a machine-specific Home Manager module or hostname branches for a common CLI package.

Home Manager installs the CLI only. Do not run `tailscale up`, `tailscale set`, login/logout, sudo, daemon installation, or service restarts from activation. Preserve differences in DNS acceptance, route acceptance, exit-node use, SSH, and advertisements between hosts.

### Generic native services

Use one reusable `modules/tailscale.nix` declaring `services.tailscale.enable` and `services.tailscale.package` through `lib.mkDefault`. Import it once from the common Darwin system configuration. Export it as `nixosModules.tailscale` from the Linux flake for reuse in existing NixOS systems. Never import system options as Home Manager options.

Do not create a Poseidon-specific service file, a production `nixosConfigurations.poseidon`, or a full replacement OS configuration. Do not populate the empty `nixos/flake.nix` to adopt a host merely to manage Tailscale.

Poseidon is Fedora 43 WSL, verified by `/etc/os-release`, not NixOS. For Fedora and compatible ordinary Linux, export a generic Nix-built `tailscale-systemd` package from `linux/tailscale-systemd.nix`. It emits only a drop-in for the existing vendor service, not a second unit. Preserve vendor security, environment files, runtime/state directories, and startup behavior. Override both `ExecStart` and `ExecStopPost` to use the same Nix package, retaining `/var/lib/tailscale/tailscaled.state`, `/run/tailscale/tailscaled.sock`, `$PORT`, and `$FLAGS`.

### Naming and package compatibility

Rename the standalone Home Manager output from `daehyun@charon` to `daehyun@poseidon` only in this deferred phase, updating active user commands and affected CI callers without an alias. This does not rename the OS, WSL registration, or Tailscale node. Preserve shared/platform modules and unrelated system settings.

Inspect pinned package versions before activation. Compatible CLI and daemon builds are required; do not silently upgrade/downgrade the live service. The earlier implementation used locked unstable Darwin Tailscale to avoid downgrading the observed Homebrew version. Recheck actual versions at migration time instead of treating that observation as permanent.

### Preservation gates and migration

Initial Cua inspection used the running app and authenticated admin console without changing settings. Retain these preservation requirements:

- Apollo's App Store client reports encrypted node state. Do not remove it unless supported equivalent key protection is available or the user explicitly accepts the concrete security change. Generic headless wiring does not waive this gate.
- Apollo accepts incoming connections, Tailscale DNS, and subnet routes, with no selected or advertised exit node. Preserve those roles; do not enable SSH, VPN On Demand, or Tailnet Lock as incidental adoption.
- Headless macOS lacks the app UI and has upstream feature limitations, including exit-node consumption/Taildrop differences. Inventory actual requirements before replacement, not after losing them.
- Prior inspection found Thales's Homebrew launchd service `system/homebrew.mxcl.tailscale`; its CLI needed `--socket=/var/run/tailscaled.socket` to reach the real headless daemon rather than a different GUI backend. Reinspect its actual executable, state directory, socket, flags, version, and preferences before cutover.
- Poseidon keeps its vendor service and current Fedora/WSL topology. Do not adopt NixOS, reinstall WSL, or add Windows startup tasks. WSL service startup promises availability only while the distribution runs; inspect simultaneous Windows/WSL Tailscale risks before migration.
- Preserve the latest inventoried device IDs, addresses, expiry, routes, DNS, ownership, local preferences, and SSH behavior. Do not restore stale historical addresses or subnets.

Before later explicit activation, back up private state and existing service declarations outside Git; establish independent recovery access. Migrate one host at a time, with exactly one daemon. Build and inspect Fedora's drop-in, retain its store path through a root-owned GC root, and review the composed vendor unit before restart. Native NixOS/nix-darwin activation is separate from Home Manager activation.

Rollback of a Home Manager/system generation does not automatically restore removed App Store software, private keys, identity, or API policy. Retain a reviewed prior-client/service recovery procedure and existing device records. Stop rather than reenroll when equivalence is unavailable.

### Deferred verification

- Evaluate both Darwin systems, the renamed Home Manager output, and the generic module in a disposable NixOS configuration; build the Fedora drop-in on Linux. Preview actual host integration without adopting a replacement OS.
- Exercise the Nix CLI against the intended authenticated daemon, not just `--version` or a process listing.
- Verify actual peer SSH, MagicDNS and public DNS, current subnet routing, exit-node behavior using a supported client, and startup after the planned restart/reboot or WSL restart.
- Preserve key protection and every inventoried identity/preference. An unavailable host or unresolved Apollo encryption gate remains explicitly blocked; successful evaluation is not daemon adoption.
- Keep Terraform policy/approval management separate from package/service activation. No automatic infrastructure applies from CI.

## Non-goals

No Headscale migration, generic deployment framework, remote state service provisioning in this phase, repository-managed enrollment keys, private-key management, client changes on other devices, unrelated access redesign, automatic updates, privileged Home Manager hooks, second daemon, or full OS/WSL adoption. Future state-backend selection remains open in the backlog.

## Sources

- [Tailscale Terraform provider](https://github.com/tailscale/terraform-provider-tailscale) — authentication and resource schemas; verify behavior against pinned v0.29.2 rather than assuming current main-branch features.
- [Tailscale: SSH](https://tailscale.com/docs/features/tailscale-ssh)
- [Tailscale: policy syntax](https://tailscale.com/docs/reference/syntax/policy-file)
- [Tailscale: omitted versus empty ACLs](https://tailscale.com/docs/reference/examples/acls)
- [Tailscale: macOS variants and migration cautions](https://tailscale.com/docs/concepts/macos-variants)
- [Tailscale: WSL 2 installation and topology limitations](https://tailscale.com/docs/install/windows/wsl2)
- Local pinned nix-darwin `modules/services/tailscale.nix`, current API exports, and prior Cua/host inspection evidence.
