# Terraform Workflow

Each configuration directory under `infra/` is an independent Terraform-compatible root module; `infra/` itself is not one. Keep infrastructure policy and inventory authoritative in configuration. Follow the [repository authorization boundary](../CLAUDE.md#yolo-boundary); this guide defines workflow, not permission to change remote resources.

| Module guide | CLI | Command working directory |
| --- | --- | --- |
| [Tailscale](tailscale/CLAUDE.md) | OpenTofu pinned by `tailscale/.opentofu-version` | Repository root; use `tofu -chdir=infra/tailscale` |
| [GitHub](github/CLAUDE.md) | Terraform compatible with `github/main.tf` | `infra/github/` |

Read the module guide for authentication, commands, import identities, and provider-specific verification. Locate the authoritative backend and workspace before plans or state-changing operations; a fresh worktree is not a new state.

The shared backend settings live in [`backend.s3.hcl`](backend.s3.hcl): Cloudflare R2 bucket `terraform-state`, region `auto`, path-style access, native locking, and S3 compatibility options. Each root's `backend.tf` declares only its state key: `github/terraform.tfstate` or `tailscale/terraform.tfstate`. Keep locking enabled; branches and worktrees share the same live state and sibling `.tflock` object.

The Apollo states were migrated and verified on 2026-11-10; R2 is now authoritative. Private before/after snapshots and retired originals are retained on Apollo and the migration workstation under `~/.config/github-iac/backups/r2-migration-20261110T195713Z-1df1c494/` and the corresponding `tailscale-iac/backups/` directory. These are recovery copies, not active local state. An older checkout with local-backend source must receive the R2 declarations before operational use; never reconfigure it back to local state to bypass its backend-initialization guard.

### Runtime environment

Backend authentication requires exported `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_ENDPOINT_URL_S3`; use an R2 API credential scoped to the selected bucket with state/lock object read, write, delete, and listing access. Keep credentials and the account endpoint out of backend configuration and command arguments. Terraform requires version 1.10 or newer; Tailscale retains its pinned OpenTofu version.

The repository-root `.env` is not loaded automatically. From the checkout containing that private file, export its trusted shell-compatible contents before changing into a module:

```sh
set -a
. ./.env
set +a
```

Worktrees do not inherit the main checkout's `.env`. Load the existing private file by its explicit path or supply the exported variables through the operator environment; do not copy secrets into Git or assume that credentials alone identify the authoritative state.

### Backend initialization

With the runtime environment exported, initialize either root from the repository root:

```sh
terraform -chdir=infra/github init -backend-config=../backend.s3.hcl -input=false -lockfile=readonly
tofu -chdir=infra/tailscale init -backend-config=../backend.s3.hcl -input=false -lockfile=readonly
```

The backend-config path is relative to the module after `-chdir`. Supply this file on every backend initialization; credential-free validation continues to use `-backend=false`. Terraform backend blocks cannot inherit settings from a child module, so the shared file is passed explicitly rather than introducing a wrapper.

When adopting this layout in an already initialized checkout, verify that the cached bucket/key match the shared configuration, then add `-reconfigure` once to update only cached backend settings. This is not a state migration; a changed destination requires the migration procedure below.

## Checks and reviewed plans

1. Use the module's CLI version and committed `.terraform.lock.hcl`. Run formatting and schema validation with `init -backend=false -input=false -lockfile=readonly` where documented. Do not update provider locks as a side effect of validation.
2. Locate the authoritative backend and workspace before an authenticated plan. Initialize with the committed lock and load credentials only at runtime, as described in the module guide.
3. Create a saved plan in a private temporary directory (`umask 077`, `mktemp -d`) and inspect that exact artifact with `show`. Saved plans contain sensitive data; never commit, publish, or share the raw file. A temporary plan is not a recovery backup.
4. Present proposed actions and risks, then stop for explicit approval of that exact saved plan. A setting-change request or successful plan is not approval of an unseen plan. Never combine planning and applying in the same unattended tool call.
5. After approval and a validated private state backup, apply the reviewed saved-plan file in a separate operation with locking enabled. Passing a saved plan skips the CLI confirmation prompt; bare `apply` instead generates a new plan and is not the reviewed-artifact workflow.

Plan exit codes with `-detailed-exitcode`: `0` means no changes, `2` means proposed changes, and `1` means failure. Do not treat exit `2` as a failed plan or ignore exit `1`.

Saved plans retain their original inputs. Replan and obtain fresh approval after changes to source, policy, CLI/provider pins, variable inputs, or observed drift. Never disable state locking. `prevent_destroy` does not prevent in-place changes or replace plan review.

## Verify an authorized apply

An apply success message alone is not completion:

1. Query the service's API or CLI and compare effective settings and preserved identities with the approved changes, using the module-specific criteria.
2. Inspect refreshed state for the intended resource bindings and managed values without printing secrets.
3. Run a fresh authenticated plan with refresh enabled and `-detailed-exitcode`; require exit `0` and no drift.

A mismatch or verification error means the operation is incomplete. Report expected versus observed state; any corrective apply needs a newly reviewed and approved plan. Remove private saved-plan artifacts after use, retaining recovery backups.

## State and recovery

- Keep one operator and one authoritative state per module. R2 native lockfiles coordinate operations on the same key, not different keys or local copies. Never disable locking or select another backend/workspace implicitly.
- Keep credentials, state, state backups, provider caches, saved plans, and secret variable files out of Git and the Nix store. The provider lock is tracked; it pins dependencies, not state access.
- Before and after each state-changing operation, including imports, ownership removal, and attempted applies that may partially fail, save and validate a private versioned backup outside the checkout. For a deliberately fresh adoption with no prior state, establish ownership and verify inventory before importing; back up the resulting state before the next mutation.
- Require successful state retrieval and valid JSON with lineage, serial, and resources before treating a file as a backup. Keep earlier backups. Recover lost state from a verified backup into the intended backend/workspace before reviewing a fresh plan; recovery and ordinary operations must not run concurrently.
- R2 does not provide S3 bucket versioning. Overwrites and deletions have no automatic historical recovery; retain verified private before/after backups outside every checkout. Restore only the intended authoritative key/workspace under exclusive access, preserving lineage and serial checks; never force-push a stale backup over newer state.
- An object missing from state is not proof it should be created. Locate existing authoritative state first, then use the module's adoption procedure if a fresh adoption is actually intended.
- To relinquish management without changing a live object, remove both resource and import membership before forgetting its state binding. Never apply a destruction plan as a bookkeeping shortcut; check provider-specific deletion behavior in the module guide.

## Worktree state handoff

Before migrating existing local state, using a relocated root operationally, or deleting an operator checkout:

1. Stop concurrent operations. Locate the existing authoritative state, workspace, and active backend metadata (`.terraform/terraform.tfstate`, which is not the resource state). Privately back up and validate the state and retain local backups outside the checkout; do not print state or credentials.
2. For the local-to-R2 migration, verify that the intended destination key has no existing state. If it exists, stop and reconcile ownership, lineage, serial, and bindings; never overwrite it. Initialize from the authoritative local state and its backend context with `terraform init -migrate-state -backend-config=../backend.s3.hcl -lockfile=readonly` (GitHub) or `tofu -chdir=infra/tailscale init -migrate-state -backend-config=../backend.s3.hcl -lockfile=readonly` (Tailscale). Review the migration prompt. Never use `init -reconfigure` to copy state, or plan/import in an empty relocated root.
3. After migration, retrieve and validate a private R2 backup, compare lineage, serial, and resource bindings with the source, confirm the workspace, and require the module-specific bindings plus a zero-drift refreshed plan. Native state writes may advance serial; require the original lineage and unchanged resource/output data, and investigate any reset. Retain the source only as a private recovery backup, not another active state. Until these checks pass, do not claim cutover or resume mutations.
4. For later checkout handoffs, R2 remains authoritative: initialize the retained module with `-backend-config=../backend.s3.hcl`, the same bucket/key, exported credentials, and its committed provider lock. Inspect existing backend metadata privately before initialization; stale local metadata must not silently redirect operations. Do not move resource state into a new local default or copy cached metadata blindly.
5. Before deleting the old worktree, verify retained-checkout access, bindings, and zero drift, and preserve any non-regenerable local state/backups privately. Backend metadata and provider caches are regenerable after their settings are verified; recovery backups are not. Never use apply, destroy, or `state rm` as a cleanup shortcut.
