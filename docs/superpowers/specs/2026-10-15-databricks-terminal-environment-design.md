# Persephone: Databricks Terminal Environment Specification

**Status:** Approved on 2026-10-15. Requirements are approved; implementation has not started. This documentation-only approval and commit do not authorize implementation, publication, or live cluster changes.

**Purpose:** Provide a familiar, reproducible terminal environment on dedicated Databricks compute without replacing or reconfiguring the Databricks runtime.

**Machine / Nix target:** `persephone` — named after the Greek goddess. This is the configuration target name, not an instruction to change an existing cluster's name or Linux hostname.

**Deployment root:** `/local_disk0/persephone`.

This spec is the source of requirements. The [synchronized implementation plan](../plans/2026-10-15-databricks-terminal-environment.md) is subordinate to it and maps the acceptance criteria to implementation tasks.

## 1. Context and established evidence

The previous Pi discussion established the goal as a familiar terminal, not a replacement for Databricks Python, Java, Spark, or notebook dependency management. Its final scope decision was **dedicated single-user compute only**.

The recorded proof of concept ran Nix 2.34.6, Fish 4.7.1, and jq 1.8.2 on an Ubuntu 24.04, x86-64 dedicated driver running as root. It used `/local_disk0/nix-terminal-poc/enter`. It did not implement the complete environment or restart restoration. These are historical results, not a claim that the installation or cluster is currently available.

The existing workstation configuration cannot be applied wholesale: it includes desktop/SSH files, workstation packages, and home-directory assumptions. Persephone selects the relevant terminal pieces instead.

## 2. Scope

### Included

- Dedicated compute assigned to one principal, initially `x86_64-linux`.
- Driver-local terminal tools accessible through SSH and the Databricks web terminal.
- Nix-managed package versions and generated terminal configuration.
- Explicit entry into Fish; no login-shell replacement.
- Prebuilt, versioned releases; installation, updates, rollback, and startup restoration.
- Configuration/state isolation from root's existing home configuration.
- Preservation of Databricks runtime behavior and existing cluster settings.

### Excluded

- Standard, serverless, group-assigned dedicated compute, and ARM64 support.
- Spark worker provisioning and distributed workload dependencies.
- Python/Java replacements, system services, sudo policy changes, and new Linux accounts.
- Full workstation Home Manager activation.
- Automatic coding-agent installation or startup.
- Durable shell history, credentials, agent sessions, or other mutable user-state synchronization.
- Changes to the existing Linux/macOS configuration targets.

## 3. User experience

### Enter and leave

From an existing SSH or web-terminal session:

```bash
/local_disk0/persephone/enter
```

The launcher enters the active release's Fish shell with the selected tools and configuration. `exit` returns to the original shell, whose environment and configuration remain unchanged.

The same launcher accepts Fish command arguments for non-interactive use:

```bash
/local_disk0/persephone/enter -c 'jq -n "1 + 1"'
```

Expected result: `2`.

### Baseline tools

| Tool | Purpose |
| --- | --- |
| direnv | Explicitly approved per-directory environment loading. |
| fd | File discovery. |
| Fish | Interactive shell. |
| fzf | Fuzzy selection. |
| Git and Git LFS | Source control. |
| Helix | Terminal editing. |
| jq | JSON processing. |
| ripgrep | Text search. |
| tmux | Terminal sessions and panes. |
| Nix | Access to the pinned package manager used by this environment. |

Coding agents and their Node/Bun runtimes are not included by default. Adding one requires an explicit package/version choice and a defined credential/state location; no unversioned startup installation is allowed.

### Familiar configuration

- Fish initialization, completions, and fzf integration work without missing-command errors. Do not inherit the workstation's `fnm` initialization unless that tool is deliberately included.
- Reuse the repository's tmux settings, with explicit configuration selection and a separate socket from unrelated tmux sessions.
- Carry over relevant Git behavior without writing `/root/.gitconfig`. The user's non-secret Git identity is an explicit deployment setting, not the Linux root identity.
- Provide a deliberate Helix configuration; do not claim an existing personal Helix configuration was found in this repository.
- direnv does not bypass its normal approval boundary or automatically trust downloaded project configuration.

## 4. Architecture

```text
Git definitions + locked dependencies
                  |
                  v
Build and verify outside Databricks
                  |
                  v
Immutable release in approved persistent storage
                  |
                  v
Driver bootstrap: verify -> restore -> check -> activate
                  |
                  v
/local_disk0/persephone/enter -> Fish + selected tools
```

Nix remains the source of truth for packages and generated configuration. The cluster restores already-built artifacts; it does not evaluate flakes, resolve floating versions, clone Git repositories, or compile source during installation/startup.

Use Nix-generated configuration initially rather than Home Manager activation. Reusing terminal settings is required where appropriate; importing the existing root `home.nix` or `packages.nix` wholesale is not.

### Why prebuilt releases

| Alternative | Tradeoff |
| --- | --- |
| Existing Home Manager configuration unchanged | Rejected: writes and packages exceed the terminal scope. |
| Evaluate/install the flake on every startup | Rejected for restoration: depends on live sources/caches and can trigger builds. |
| Prebuild the complete environment and restore it | Selected: predictable restoration, explicit versions, and offline rollback; requires release packaging and a bootstrap. |

## 5. Storage and ownership

```text
/nix/store/                            actual packages and immutable configuration

/local_disk0/persephone/
  releases/<release-id>/               release metadata and profile references
  current -> releases/<release-id>
  previous -> releases/<previous-id>
  user/
    config/
    data/
    state/
    cache/
  nix/                                pinned bootstrap, Nix config/state, GC roots
  enter                               stable entry point
```

| Data | Lifetime / location |
| --- | --- |
| Package and configuration definitions | Persistent in Git. |
| Published releases | Persistent in approved artifact storage. |
| Actual executable closure | Local `/nix/store`; recreated after compute replacement. |
| Active and previous release references | Local deployment root. |
| Mutable user data, caches, and history | Local and disposable. |
| Secrets and private keys | Outside derivations and published releases; no automatic persistence or copying. |

An approved Unity Catalog Volume is the preferred release distribution location where available. It is **not** a live Nix store. Persistent-storage access from init-script execution must be demonstrated; notebook access alone is insufficient.

The historical proof-of-concept directory and unrelated existing Nix store contents are not removed as incidental cleanup. If an existing installation cannot safely coexist, stop before mutation and report the incompatibility.

## 6. Isolation and runtime compatibility

The entered environment must:

- Select explicit XDG configuration, data, state, and cache locations under `/local_disk0/persephone`.
- Contain Nix configuration and default-profile initialization using its XDG layout; no `/root/.nix-profile` side effect.
- Select tool-specific paths for tools not fully controlled by XDG variables.
- Preserve `HOME`, Databricks authentication variables, and the existing Python/Spark environment.
- Make no changes to `/root/.bashrc`, `/root/.gitconfig`, `/etc/shells`, the login shell, or system services.
- Add no Nix daemon and change no cluster-wide PATH, Python, Java, or Spark settings.

The terminal retains the identity provided by Databricks. On the tested dedicated driver that identity was root. Directory separation is **not a security sandbox**; trusted tools and coding agents can still modify the runtime if instructed to do so.

## 7. Release and lifecycle behavior

### Release identity and trust

Each release has an immutable content-derived ID, source revision, dependency-lock identity, architecture, package-manager version, profile store path, and observed tool versions. Its payload includes the complete package/configuration closure, pinned Nix bootstrap, bootstrap script, manifest, and checksums.

The initial dependency baseline is the previously exercised nixpkgs revision `035cdf085e9adbb965e6031d0d9d0c1ed2731480`, with Nix 2.34.6 for bootstrap. Version changes require a new built and verified release.

Verify the release before executing its bootstrap. Unattended installation pins a trusted checksum-file digest in the reviewed init script. Restrict publication permissions; a checksum downloaded alongside an arbitrary installer does not establish authenticity. Do not use a mutable `latest` pointer for startup selection.

### Install and update

1. Verify release trust, integrity, architecture, and format before mutation.
2. Restore bootstrap and complete closure locally without downloading missing packages.
3. Run candidate checks before activation.
4. Activate the candidate through an atomic active-release switch.
5. Retain the previous working release for rollback.

Only one installation/activation/rollback operation may mutate deployment state at a time. Reinstalling the current release is idempotent and preserves the previous rollback target. Failure or interruption before activation leaves the existing active release usable; first-install failure leaves no release falsely marked active.

### Rollback

Rollback validates and reactivates the previous working release without builds, downloads, or dependency resolution. If no previous release exists, report that condition without mutation.

Rollback affects packages and release-managed configuration, not mutable user data. Existing Fish/tmux processes are not killed or migrated. Newly entered sessions use the selected active release. Active and previous closures stay GC-rooted, and there is no automatic store garbage collection in this implementation.

### Compute replacement

Local installation and mutable state may disappear. Restore the explicitly selected published release; do not assume local rollback history survives. Older published releases remain available for an explicit startup-release change.

## 8. Startup restoration and operational safety

Prove manual installation, update, and rollback before attaching startup automation.

The final startup mechanism is a small cluster-scoped init script that:

- Uses `DB_IS_DRIVER` to skip installation on workers.
- Selects a fixed release and trusted integrity metadata from approved persistent storage.
- Restores and checks that release without builds or external package fetching.
- Preserves other init scripts and cluster settings.
- Returns a non-zero exit code on failure instead of claiming successful provisioning.

**Risk: a failed attached init script can prevent the cluster from starting.** Recovery is to detach the terminal init script or repoint it to a known-good published release, then restart with explicit approval. There is no silent fallback to an unknown or incomplete environment.

A missing Volume, insufficient privileges, or unavailable artifact storage is an unmet deployment prerequisite, not permission to create catalogs, invent credentials, or change cluster policy.

Do not start/restart compute, attach scripts, or change live cluster configuration without explicit approval in the implementation session. The historically tested personal cluster is a candidate, not ongoing authorization.

## 9. Acceptance criteria

| ID | Observable acceptance criterion |
| --- | --- |
| A1 | The pinned environment builds outside Databricks and restores into a fresh, private local store with package-network access disabled. |
| A2 | The real SSH and web-terminal surfaces can enter Fish, execute jq, edit with Helix, use fzf, and operate tmux panes with the intended configuration. |
| A3 | Entering/exiting leaves the parent environment and protected root/system configuration unchanged; Nix creates no root default-profile link or daemon. |
| A4 | The same Databricks notebook context retains its Python executable/environment, and `spark.range(3).count()` still returns `3` after installation. |
| A5 | Updating between releases with observably different configuration works; corrupt or failing candidates cannot replace the valid active release. |
| A6 | Reinstalling the active release preserves rollback history; concurrent operations cannot interleave activation; an interrupted candidate is not advertised as active. |
| A7 | Rollback restores the previous packages/configuration without network or builds and does not terminate existing sessions. |
| A8 | Existing compatible Nix store contents and unrelated proof-of-concept files are preserved. |
| A9 | After an approved compute replacement/restart with initially absent terminal installation, the pinned environment returns without manual repair. |
| A10 | The init script skips workers; claim worker-runtime evidence only if exercised on a multi-node target, without resizing solely for the check. |
| A11 | Operating documentation covers build, publication, entry, update, rollback, state loss, and failed-startup recovery using exercised procedures. |

Build checks alone do not prove terminal usability or restart restoration. Report unexercised behavior explicitly rather than treating the historical proof of concept as evidence for the new lifecycle.

## 10. Approved design decisions

The following defaults were approved with this specification:

1. **Name and path:** `persephone`, `/local_disk0/persephone`, and Nix target `databricks#persephone`.
2. **Tools:** the baseline above; coding agents are opt-in additions.
3. **Configuration:** Nix-generated files initially, without full Home Manager activation.
4. **Persistence:** definitions/releases persist; mutable local user state does not.
5. **Startup coupling:** accept explicit cluster-start failure on bootstrap failure only after manual lifecycle proof.

Spec approval establishes requirements; it does not itself authorize implementation or live compute actions. Changes to these decisions require updating this spec and synchronizing the implementation plan before execution.

## References

- [Cluster-scoped init scripts](https://learn.microsoft.com/en-us/azure/databricks/init-scripts/cluster-scoped): launch-failure behavior, script limits, and assigned-principal access.
- [Init-script environment variables](https://learn.microsoft.com/en-us/azure/databricks/init-scripts/environment-variables): driver-only execution guard.
- [Init-script storage recommendations](https://learn.microsoft.com/en-us/azure/databricks/init-scripts/): supported persistent storage and Runtime requirements.
- [Detailed implementation plan and Pi transcript provenance](../plans/2026-10-15-databricks-terminal-environment.md).
