# Tailscale Terraform Implementation Plan

> **For agentic workers:** Use executing-plans. Implement only Terraform-compatible tailnet configuration. Retain the Nix design and its stash. The explicitly authorized saved-plan application below is complete; further changes require separate review and authorization.

**Goal:** Adopt the current ownership-based SSH policy and existing DNS, expiry, and route settings without changing the live tailnet or host installations.

**Architecture:** One OpenTofu root at `terraform/tailscale/` owns eight existing resources using the official provider. The user-selected simple policy supersedes the earlier Muse-specific tag transition. Nix client/service management remains a separate deferred phase.

**Tech Stack:** OpenTofu 1.13.1, Tailscale provider ~> 0.29.2, HuJSON, credential-free GitHub Actions validation.

## Execution boundary

The initial no-apply boundary allowed source changes, private state adoption, validation, and read-only inspection. The user later authorized applying this root. That application is complete: one policy-only cleanup, no host changes. Do not treat it as authorization for additional policy/DNS changes, tags, client/service activation, enrollment, or credential creation/expansion.

Before this boundary, eleven resources were imported and the earlier merged policy alone was applied. Fresh API inspection now shows the user's simpler policy already live, a different Thales device record, and subnet `192.168.2.0/24`. Adopt these current facts rather than restoring the historical snapshot. No successful Muse-originated SSH or daemon migration is claimed.

## Task 1: Scope and layout

**Files:** spec, this plan, `terraform/tailscale/`, README, `.github/workflows/validate.yml`.

- [x] Keep shared Home Manager tooling and generic native services in the spec as deferred, including Fedora integration and Apollo's encrypted-state gate.
- [x] Move the whole existing `infra/tailscale/` directory, including ignored state/backups/cache, to `terraform/tailscale/`. Do not initialize a second empty adoption state.
- [x] Leave existing Nix CI and host configuration unchanged; do not introduce dependencies on stashed NixOS/Fedora outputs.
- [x] Add credential-free OpenTofu CI checks using the version file and locked provider.
- [x] Finish README with the simplified policy, eight-resource ownership, safe commands, and state recovery.

## Task 2: Current tailnet declarations

**Files:** `terraform/tailscale/{versions,main,dns,devices,imports}.tf`, `policy.hujson`, `.opentofu-version`, `.terraform.lock.hcl`, root `.gitignore`, `.env.example`.

- [x] Pin OpenTofu 1.13.1 and provider ~> 0.29.2; retain the dependency lock and explicit inventoried tailnet ID.
- [x] Declare the user's policy behavior: member-to-self SSH `accept` for non-root/root and existing member Funnel capability. Omit unnecessary comments and empty `tagOwners`/`sshTests`, and leave `acls` and `grants` absent.
- [x] Remove the obsolete tag resource, Muse-only rule, tagged personal fallback, and tag-specific tests. No device ownership transition remains in scope.
- [x] Preserve MagicDNS, disabled DNS override, no extra search paths, and the API's one logical Cloudflare nameserver `1.1.1.1` with exit-node use disabled.
- [x] Preserve expiry settings for all four existing devices. Adopt current Thales node ID `nhesn3Xjj111CNTRL`, not the deleted historical record.
- [x] Preserve current Thales approved routes `192.168.2.0/24`, `0.0.0.0/0`, `::/0`, and Poseidon's two exit routes.
- [x] Keep lifecycle destruction protection, private state/plan/cache exclusions, and empty credential examples. Credentials stay outside Git/Nix store.

## Task 3: Local state reconciliation without apply

- [x] Inspect the actual policy, device ownership, current Thales ID/IP, and advertised/enabled routes with read-only API calls.
- [x] Back up local state privately outside Git with mode 0600.
- [x] Forget the three obsolete `tailscale_device_tags.ssh` bindings using local `state rm`, not provider deletion. Confirm the inspected devices have no tags first.
- [x] Forget only the stale Thales key/route bindings locally, then import those settings against the inspected current node. Imports read remote settings without changing them.
- [x] Confirm local state lists eight resource addresses: policy, DNS, four key settings, and two route settings. Never print private state contents.

Operators with older local state must perform the same reviewed adoption against a fresh inventory, after a private backup. Do not apply a plan that destroys obsolete tag resources or creates settings against a missing node merely to repair local bookkeeping.

## Task 4: Verification

Run from the repository root:

```sh
tofu -chdir=terraform/tailscale fmt -check
tofu -chdir=terraform/tailscale init -backend=false -input=false -lockfile=readonly
tofu -chdir=terraform/tailscale validate
```

- [x] Run the final credential-free checks after the simplification.
- [x] Validate the actual source through `POST /api/v2/tailnet/{tailnet}/acl/validate`; confirm equivalent live policy behavior after omitting unused empty fields.
- [x] Exercise temporary owner-based SSH acceptance tests for `daehyun` and `root` on current Thales/Poseidon. Remove the rule only in memory for a failing negative control. Both probes use the validation endpoint only; source policy tests remain omitted.
- [x] Review a fresh authenticated plan and apply its exact saved artifact only after explicit authorization. The only action was `tailscale_acl.tailnet` update, with equivalent SSH/Funnel behavior.
- [x] Check Terraform CI syntax and existing Nix evaluations; review directory/state safety and policy scope. No authenticated CI or permanent source-copy tests.
- [x] Record exercised results and any real runtime limits; no claim of live traffic or Nix activation.

Observed: formatting, locked initialization, and provider validation passed. Read-only policy validation and temporary positive/negative SSH probes passed. Initial adoption's plan exited 0 with no changes. After requested policy cleanup, a fresh plan exited 2 with only `tailscale_acl.tailnet` updated; the candidate's SSH/Funnel behavior matches the live document. Actionlint and existing Nix evaluations passed. State/cache/plan exclusions and the non-ignored provider lock were checked.

On 2026-11-08, the user-authorized saved plan applied successfully: zero added, one changed, zero destroyed. Authoritative post-apply API reads confirmed the source policy and unchanged DNS, routes, IDs/IPs, tags, ownership, and expiry. The final plan exited 0 with no changes. Pre/post state, API snapshots, and verification are private under `~/.config/tailscale-iac/backups/2026-11-08/apply-130634/`. No host activation or secondary DNS change occurred; actual SSH traffic and daemon startup were not exercised. The DNS resource remains provider-marked alpha.

This PR adds only Terraform validation to CI. Generic Nix CI discovery, nested workflow instructions, and repository-wide worktree policy changes are excluded. The original mixed branch preserves that separate work; Nix Tailscale implementation stays stashed.

## Task 5: Secondary DNS correction

- [x] Add Google `8.8.8.8` alongside Cloudflare `1.1.1.1` in the existing DNS resource; keep MagicDNS on, override off, no extra search paths, and exit-node DNS use off for both.
- [x] Update the spec and README: this is additional-provider redundancy, not ordered failover, and clients retain local DNS preference.
- [x] Validate and inspect a fresh plan; require only the DNS resource update and retain all existing settings.
- [ ] Apply only after separate authorization, then verify the resolver list and a zero-change final plan. The earlier application did not include secondary DNS.

Observed: formatting and provider validation passed. The authenticated saved-plan review proposed only an in-place update to `tailscale_dns_configuration.tailnet`, adding `8.8.8.8` alongside `1.1.1.1`. All non-resolver DNS fields and the other seven resources were unchanged. The temporary private plan was removed; no DNS application occurred.

## Task 6: Declarative adoption and safe unmanagement

- [x] Reproduce the gap: before import declarations, fresh state plans eight creates and no imports.
- [x] Add import declarations for the policy, aggregate DNS, four device keys, and two router approvals; reuse the same device/router maps as the resources.
- [x] Require OpenTofu/Terraform >= 1.7 for import loops while retaining the OpenTofu 1.13.1 pin.
- [x] Document ownership/import identities, import-plan updates, and coordinated source/import removal plus local state forgetting. Do not imply `state rm` alone stops management.
- [x] Verify fresh-state adoption, idempotence with current state, and the documented unmanagement procedure in disposable copies; no actual imports/applies or operator-state mutation.

Observed: fresh state changed from eight creates/no imports to eight imports/no creates or deletes. Existing state skips all imports. Both plans retain only the unapplied DNS update. Removing Apollo from the shared map and forgetting its temporary state binding plans no operation on that released instance. Original state remained byte-for-byte unchanged; all temporary inputs/state/plans were removed.

## Deferred Nix phase

Do not restore `WIP: Tailscale Nix configuration (not applied)` in this phase. The spec retains shared CLI installation, generic NixOS/nix-darwin service management, the generic Fedora vendor-service drop-in, the future Home Manager rename, package compatibility, preservation/recovery gates, and actual restart/network verification. Poseidon remains Fedora WSL; Apollo's App Store encryption gate remains unresolved. No privileged Home Manager hooks or full OS adoption.
