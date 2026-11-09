# Terraform Workflow

Each configuration directory under `terraform/` is an independent Terraform-compatible root module; `terraform/` itself is not one. Keep infrastructure policy and inventory authoritative in configuration. Follow the [repository authorization boundary](../CLAUDE.md#yolo-boundary); this guide defines workflow, not permission to change remote resources.

| Module guide | CLI | Command working directory |
| --- | --- | --- |
| [Tailscale](tailscale/CLAUDE.md) | OpenTofu pinned by `tailscale/.opentofu-version` | Repository root; use `tofu -chdir=terraform/tailscale` |
| [GitHub](github/CLAUDE.md) | Terraform compatible with `github/main.tf` | `terraform/github/` |

Read the module guide for authentication, commands, backend details, import identities, and provider-specific verification. Use the checkout holding that module's authoritative state for plans and state-changing operations, not a fresh worktree with an empty state.

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

- Keep one operator and one authoritative state per module. Worktrees and branches do not isolate live resources; local locks coordinate the same state file, not independent copies or machines. Do not select or migrate a shared backend implicitly.
- Keep credentials, state, state backups, provider caches, saved plans, and secret variable files out of Git and the Nix store. The provider lock is tracked; it pins dependencies, not state access.
- Before and after each state-changing operation, including imports, ownership removal, and attempted applies that may partially fail, save and validate a private versioned backup outside the checkout. For a deliberately fresh adoption with no prior state, establish ownership and verify inventory before importing; back up the resulting state before the next mutation.
- Require successful state retrieval and valid JSON with lineage, serial, and resources before treating a file as a backup. Keep earlier backups. Recover lost state from a verified backup into the intended backend/workspace before reviewing a fresh plan; recovery and ordinary operations must not run concurrently.
- An object missing from state is not proof it should be created. Locate existing authoritative state first, then use the module's adoption procedure if a fresh adoption is actually intended.
- To relinquish management without changing a live object, remove both resource and import membership before forgetting its state binding. Never apply a destruction plan as a bookkeeping shortcut; check provider-specific deletion behavior in the module guide.

## Worktree state handoff

Before deleting a checkout holding authoritative local state:

1. Ensure no concurrent state operation is running. Privately back up the active state and its local backups outside the worktree; do not print their contents.
2. After merging, select the module's default state location in the retained checkout. Do not overwrite an existing destination; reconcile lineage, serial, bindings, workspace, and ownership first.
3. Move the active state and local backups with private permissions. Verify bytes and resource bindings before retiring the former active copy. Provider caches are regenerable; state is not.
4. Initialize the retained module with its committed lock, confirm the intended workspace, and require all module-specific bindings plus a zero-drift refreshed plan before deleting the old worktree. Never use apply, destroy, or `state rm` as a cleanup shortcut.
