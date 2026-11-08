# Tailscale Terraform Implementation Plan

> **For agentic workers:** Use executing-plans. Implement only Terraform-compatible tailnet configuration. Retain the Nix design and its stash. The explicitly authorized saved-plan application below is complete; further changes require separate review and authorization.

**Goal:** Manage the existing tailnet through native OpenTofu with Cloudflare `1.1.1.1` as the sole global DNS resolver, preserving SSH/Funnel behavior, device key expiry, and route approvals. Every live change requires a reviewed saved plan and explicit apply authorization. Host/client changes remain deferred.

**Architecture:** One OpenTofu root at `terraform/tailscale/` owns eight existing resources using the official provider. The user-selected simple policy supersedes the earlier Muse-specific tag transition. Nix client/service management remains a separate deferred phase.

**Tech Stack:** OpenTofu 1.13.1, Tailscale provider ~> 0.29.2, HuJSON, credential-free GitHub Actions validation.

## Execution boundary

The initial no-apply boundary allowed source changes, private state adoption, validation, and read-only inspection. The user later separately authorized the policy cleanup, Google DNS extension, and Cloudflare-only removal; all were applied and verified. Every further change requires a new reviewed plan and explicit approval. Earlier authorization does not cover other policy/DNS changes, tags, client/service activation, enrollment, or credential creation/expansion.

Before this boundary, eleven resources were imported and the earlier merged policy alone was applied. Fresh API inspection now shows the user's simpler policy already live, a different Thales device record, and subnet `192.168.2.0/24`. Adopt these current facts rather than restoring the historical snapshot. No successful Muse-originated SSH or daemon migration is claimed.

## Task 1: Scope and layout

**Files:** spec, this plan, `terraform/tailscale/`, README, `.github/workflows/validate.yml`.

- [x] Keep shared Home Manager tooling and generic native services in the spec as deferred, including Fedora integration and Apollo's encrypted-state gate.
- [x] Move the whole existing `infra/tailscale/` directory, including ignored state/backups/cache, to `terraform/tailscale/`. Do not initialize a second empty adoption state.
- [x] Leave existing Nix CI and host configuration unchanged; do not introduce dependencies on stashed NixOS/Fedora outputs.
- [x] Add credential-free OpenTofu CI checks using the version file and locked provider.
- [x] Document the simplified policy, eight-resource ownership, safe commands, and state recovery; agent operational guidance now lives in `terraform/CLAUDE.md`.

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

This PR adds only Terraform validation to CI and retains the Nix validation inherited from main. Additional generic CI refactoring, CI-specific agent guides, and worktree-policy changes are excluded. The user-requested Terraform workflow guide lives in `terraform/CLAUDE.md`; Nix Tailscale implementation stays stashed.

## Task 5: Secondary DNS extension — applied, superseded by Task 11

- [x] Add Google `8.8.8.8` alongside Cloudflare `1.1.1.1` in the existing DNS resource; keep MagicDNS on, override off, no extra search paths, and exit-node DNS use off for both.
- [x] Update the spec and agent guide: this is additional-provider redundancy, not ordered failover, and clients retain local DNS preference.
- [x] Validate and inspect a fresh plan; require only the DNS resource update and retain all existing settings.
- [x] Apply the exact saved plan after separate authorization, then verify the resolver list and a zero-change final plan. No host/client changes.

On 2026-11-08, the user authorized the reviewed artifact `d21fa52cfdaf`. OpenTofu reported zero added, one changed, zero destroyed. API reads confirmed Cloudflare plus Google, unchanged DNS preferences, policy, device identities/addresses/ownership/tags/expiry, and advertised/approved routes. All eight state bindings were preserved; the only other raw state difference was semantically equivalent ACL JSON formatting. The final refreshed plan exited 0. Private state, API, plan, and verification evidence is under `~/.config/tailscale-iac/backups/2026-11-08/dns-apply-214625-270538/`. The later Cloudflare-only preference and separately approved removal are recorded in Task 11.

## Task 6: Declarative adoption and safe unmanagement

- [x] Reproduce the gap: before import declarations, fresh state plans eight creates and no imports.
- [x] Add import declarations for the policy, aggregate DNS, four device keys, and two router approvals; reuse the same device/router maps as the resources.
- [x] Require OpenTofu/Terraform >= 1.7 for import loops while retaining the OpenTofu 1.13.1 pin.
- [x] Document ownership/import identities, import-plan updates, and coordinated source/import removal plus local state forgetting. Do not imply `state rm` alone stops management.
- [x] Verify fresh-state adoption, idempotence with current state, and the documented unmanagement procedure in disposable copies; no actual imports/applies or operator-state mutation.

Before the DNS application, fresh state changed from eight creates/no imports to eight imports/no creates or deletes. Existing state skipped all imports. Both plans then retained only the unapplied DNS update. Removing Apollo from the shared map and forgetting its temporary state binding planned no operation on that released instance. Original state remained byte-for-byte unchanged; all temporary inputs/state/plans were removed.

## Task 7: State backend selection — deferred

The user chose to start with default local state and keep every future backend option open. Evaluation and any later migration are tracked in `BACKLOG.md` (INFRA-6); no Thales, SSH, HTTP, S3, rclone, SMB, database, or managed-service choice is committed to.

Earlier Thales preparation installed the pinned OpenTofu engine and created an isolated source worktree. No authoritative state or credentials were transferred, no state service was started, and no host configuration or tailnet setting was activated. The explicit backend path and runner-only instructions have been removed.

## Task 8: Resume default local state

- [x] Remove the explicit backend declaration and document the default root-module state location.
- [x] Add the open-ended backend decision to the repository backlog.
- [x] Back up and relocate the existing authoritative local state into the active operator checkout, with one active file and private recovery copies.
- [x] Initialize and validate the default local backend; verify all eight bindings, no imports/creates/deletes, and only the pending DNS update. Do not apply infrastructure.

Before the DNS application, initialization, formatting, and validation passed. The active default state retained identical bytes and all eight bindings, with mode 0600 and private before/after backups. The former active file was retired. The authenticated plan exited 2 for the then-pending DNS update only; no imports, creates, deletes, or infrastructure apply occurred during that verification.

## Task 9: Custom Python apply helper — deferred

The previously implemented helper is deferred by the latest BTW decision: use native OpenTofu for now. Its code, tests, and CI step have been removed. Reconsider custom safeguards only if they justify the additional maintenance.

## Task 10: Native workflow and agent guidance

- [x] Put reviewed-plan approval, commands, and post-apply API/state/zero-drift verification in `terraform/CLAUDE.md`. Root `CLAUDE.md` retains global policy and links the scoped guide; README remains human-facing.
- [x] Replace helper instructions with native plan/show/apply commands, private saved plans, and an explicit warning that saved-plan apply skips confirmation.
- [x] Remove the custom helper, tests, CI step, and now-unused bytecode exclusion. Keep CI credential-free and preserve the Nix deferral.
- [x] Smoke-test native formatting, locked initialization, validation, plan saving, and show without applying. Confirm the DNS-only plan and unchanged authoritative state; remove temporary plan artifacts.

Before the DNS application, shared Nix checks passed, including validation error handling, formatting, and Linux/both Darwin evaluations. OpenTofu formatting, locked initialization, validation, and actionlint passed. Native plan/show used a mode-0600 saved plan in a mode-0700 temporary directory; only the then-pending DNS nameserver update was proposed, with no imports/creates/deletes. Authoritative state remained byte-for-byte unchanged and temporary artifacts were removed. No infrastructure apply occurred during that smoke test.

## Task 11: Cloudflare-only DNS

- [x] Set the latest desired resolver list to only `1.1.1.1`; retain MagicDNS, disabled local override, empty search paths, and disabled exit-node DNS use.
- [x] Record the completed Google extension and make its later removal a separate approval boundary.
- [x] Validate and present a fresh saved plan removing only Google, with the other seven resources unchanged.
- [x] Apply only after explicit approval of that new plan, then verify API/state preservation and a zero-change final plan.

On 2026-11-08 at 22:13 UTC, the user-approved artifact `f878d4dc6b1c` removed Google with zero added, one changed, zero destroyed. API reads confirmed only `1.1.1.1`, unchanged MagicDNS/local-override/search-path/exit-node settings, policy, device identities/addresses/ownership/tags/expiry/SSH flags, and advertised/approved routes. All eight state bindings and the other seven managed settings were preserved. The fresh authenticated plan exited 0 with no changes. Private before/after state, API snapshots, the approved plan, and verification evidence are under `~/.config/tailscale-iac/backups/2026-11-08/cloudflare-only-221322-895845/`. The temporary applied plan was retired. No host/client activation or backend migration occurred.

## Deferred Nix phase

Do not restore `WIP: Tailscale Nix configuration (not applied)` in this phase. The spec retains shared CLI installation, generic NixOS/nix-darwin service management, the generic Fedora vendor-service drop-in, the future Home Manager rename, package compatibility, preservation/recovery gates, and actual restart/network verification. Poseidon remains Fedora WSL; Apollo's App Store encryption gate remains unresolved. No privileged Home Manager hooks or full OS adoption.
