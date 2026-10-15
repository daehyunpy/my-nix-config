# Persephone: Databricks Dedicated-Compute Terminal Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Use superpowers:subagent-driven-development only where independent work satisfies the repository's delegation rules. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Synchronized with the [Persephone specification](../specs/2026-10-15-databricks-terminal-environment-design.md), approved on 2026-10-15. The spec is the source of requirements and takes precedence over this plan. Implementation has not started; this documentation-only approval and commit do not authorize implementation, publication, cluster configuration changes, compute startup, or restart. Commands below describe future acceptance checks; they have not been run as part of writing this plan.

**Goal:** Reproduce the user's familiar, Nix-managed terminal environment on dedicated single-user Databricks compute, including isolated configuration, versioned updates, rollback, and restoration after compute replacement.

**Architecture:** Build and export a complete, pinned `x86_64-linux` environment outside Databricks. Publish an immutable release to approved persistent storage, restore its closure to the driver's local `/nix/store`, and enter it through an explicit launcher. A small driver-only, cluster-scoped init script eventually restores an explicitly selected release at startup; it does not provision Spark workers or alter Databricks runtime configuration.

**Machine name:** `persephone`, randomly selected from Greek goddesses. Use this name for the Nix target. It does not authorize renaming an existing Databricks cluster or changing the runtime's hostname.

**Tech Stack:** Nix flakes and closure export/import, Bash bootstrap scripts, Fish, Helix, tmux, Git, Azure Databricks dedicated compute, and an approved Unity Catalog Volume for release distribution where available.

## Global Constraints

- Dedicated single-user compute only. Standard, serverless, and group-assigned dedicated compute are out of scope.
- Initial target: `x86_64-linux`; reject other architectures rather than downloading another build implicitly.
- No changes to Databricks Python, Java, Spark, system login shell, sudo policy, or system services.
- No Nix daemon or new Linux accounts.
- No blanket import of root `home.nix` or `packages.nix`.
- No source compilation, flake evaluation, Git checkout, floating version resolution, or package-cache dependency during restoration on compute.
- No live Nix store on a Volume, workspace filesystem, or DBFS. Use local `/nix/store`.
- No default-profile or configuration writes under `/root`; explicitly contain Nix state and tool configuration.
- Preserve the Databricks-provided `HOME`, authentication environment, Python environment, and Spark environment. Isolation is configuration isolation, not a security sandbox.
- Credentials, private keys, and authentication caches must not enter Nix derivations, exported closures, manifests, or published releases.
- No automatic coding-agent startup. Agent binaries are optional and require explicit package selection and isolated state before inclusion.
- Installed tools, shell history, caches, and other mutable local state are disposable across compute replacement. Git definitions and published releases are persistent; user-state synchronization is not included.
- Preserve existing unrelated `/nix` contents and existing cluster init scripts. Do not delete the proof of concept without identifying its ownership and obtaining removal approval.
- No compute start/restart or live cluster edits without explicit approval in the implementation session.
- Startup failures are explicit: a failed attached init script can prevent the cluster from starting. Do not silently continue with a broken terminal installation.

---

## 1. Context transferred from the Pi thread

Source transcript:

```text
~/.pi/agent/sessions/--home-daehyun-Workspaces-project-manager--/2026-10-14T15-39-58-429Z_01a13b12-0256-7064-94be-a84bd8fe8dd3.jsonl
```

Relevant entries:

| Line | Context |
| --- | --- |
| 201 | Request to use this Nix setup in Databricks. |
| 233 | Goal narrowed to a familiar terminal, not replacement of the Databricks runtime. |
| 241 | Local `/nix/store`, local profiles, persistent definitions and release artifacts. |
| 325 | Dedicated-compute Fish/jq proof of concept reported successful. |
| 347 | Proposal for pinned external builds, isolated state, releases, rollback, and bootstrap. |
| 378 | Serverless probe found a non-root ARM64 environment with namespace restrictions. |
| 379–382 | User explicitly narrowed scope to dedicated compute only. |

Recorded dedicated-compute evidence, not a statement about current cluster state:

- Profile used: `DEFAULT`.
- Cluster: `0805-173524-il7lah0a`, assigned to `dyou@goremutual.ca`.
- Runtime: `16.4.x-scala2.12`; Ubuntu 24.04, x86-64, driver execution as root.
- Nix 2.34.6, Fish 4.7.1, and jq 1.8.2 were exercised successfully.
- Initial nixpkgs revision: `035cdf085e9adbb965e6031d0d9d0c1ed2731480`, also present in the repository's Linux lockfile at planning time.
- Launcher: `/local_disk0/nix-terminal-poc/enter`.
- The proof of concept initially created `/root/.nix-profile`; the agent removed the dangling test-created link and verified isolation using Nix's XDG layout.
- No restart bootstrap or full terminal configuration was implemented.

Do not repeat these experiments merely to reconfirm the historical results. New checks should exercise the new release/bootstrap behavior.

## 2. Approach and boundaries

### Alternatives considered

| Approach | Decision |
| --- | --- |
| Apply existing Home Manager configuration unchanged | Reject. `home.nix` writes desktop/SSH files and initializes `fnm`; the shared package set includes Java, Python tooling, and unrelated workstation tools. |
| Evaluate the flake and install packages on every startup | Reject for restoration. Introduces live source/cache dependencies and the risk of compilation on the driver. |
| Prebuild and export a complete release outside Databricks | Recommend. Keeps versions explicit, removes build work from startup, and supports rollback. |

Use Nix-generated configuration initially, not Home Manager activation. This matches the previous proposal's requirement to prove every write is contained before considering activation. Home Manager migration is not required to deliver this plan.

### Baseline tools

Create the package list alphabetically, following repository convention:

```nix
pkgs: [
  pkgs.direnv
  pkgs.fd
  pkgs.fish
  pkgs.fzf
  pkgs.git
  pkgs.git-lfs
  pkgs.helix
  pkgs.jq
  pkgs.ripgrep
  pkgs.tmux
]
```

Nix itself is supplied by the pinned bootstrap and remains available inside the entered environment. Export Bash and any launcher/check dependencies as part of the closure; do not assume their presence through the developer's PATH.

Pi, OMP, OpenCode, Node, and Bun are not silently added. The prior proposal treated agents and their runtimes as optional. If selected during review, extend the package/release requirements before implementation; do not use unpinned npm installs or download "latest" during startup.

### Configuration policy

- Fish: explicit generated initialization, selected completions, fzf integration, and opt-in direnv integration. Do not copy the existing `fnm env` initialization without its deliberate inclusion.
- Git: carry over relevant behavior from `home.nix:44–78`, with a generated global configuration selected using `GIT_CONFIG_GLOBAL`; do not write `/root/.gitconfig` or embed credentials. Git identity is an explicit non-secret deployment setting, not inferred from local root identity.
- Helix: use a generated configuration selected explicitly; do not imply an existing personal Helix configuration was discovered in this repository.
- tmux: reuse `home-files/tmux/tmux.conf` as release content. Select it explicitly and use a dedicated socket, so existing tmux servers do not capture the new environment.
- The entered environment changes only the shell process and descendants. Exiting leaves the parent environment unchanged.
- Check both XDG-aware tools and tools that normally inspect `$HOME`; XDG variables alone do not establish isolation.

## 3. File map

The following are planned implementation files; this document creates none of them.

| File | Responsibility |
| --- | --- |
| `databricks/flake.nix` | `x86_64-linux` environment output named `persephone`, pinned inputs, closure-bearing launcher and configuration, build checks. |
| `databricks/flake.lock` | Complete dependency lock, starting at the tested nixpkgs revision. |
| `databricks/packages.nix` | Sorted, explicit terminal package set. |
| `databricks/config.nix` | Generated Fish, Git, Helix, and tmux configuration plus the entered-shell launcher. |
| `databricks/release.sh` | External build/export, pinned Nix bootstrap packaging, manifest, checksums. |
| `databricks/bootstrap.sh` | Offline restore, candidate validation, activation, status, rollback, GC roots. |
| `databricks/init.sh` | Small cluster-scoped adapter with driver guard and one pinned release selection. |
| `databricks/tests/lifecycle.sh` | Consumer-visible restore/update/failure/rollback regression scenarios in a disposable Linux environment. |
| `README.md` | Databricks operating instructions and recovery procedure. |

Reuse `home-files/tmux/tmux.conf:1–12`. Keep the existing Linux/macOS flakes, lockfiles, root home configuration, and package list unchanged. Do not introduce a second shared configuration framework just for this target.

## 4. Interfaces and release contract

### Build interface

```bash
nix build ./databricks#persephone --no-link --print-out-paths
bash databricks/release.sh /tmp/databricks-terminal-releases
```

`packages.x86_64-linux.persephone` is the closure root. It contains the tool profile, generated configuration, a release-local `bin/enter`, and a non-interactive `bin/check` that exercises the tools without launching an interactive session.

`release.sh` accepts one output directory, refuses a dirty source snapshot, and prints the completed release directory only after all artifacts have been produced and verified. Build failures must not leave a directory that looks publishable. There is no automatic publication or cluster action.

### Release contents

Each release is immutable after publication:

```text
<release-id>/
  manifest.json
  SHA256SUMS
  nix-bootstrap.tar.xz
  closure.nar
  bootstrap.sh
```

Manifest fields:

| Field | Meaning |
| --- | --- |
| `format_version` | Integer `1`; unknown formats are rejected. |
| `release_id` | SHA-256 of the identity record defined below; not a mutable `latest` label. |
| `source_revision` | Git revision of the clean source used for the build. |
| `lock_sha256` | SHA-256 of `databricks/flake.lock`. |
| `system` | Exactly `x86_64-linux` initially. |
| `nix_version` | Exactly `2.34.6` for the initial bootstrap. |
| `profile_store_path` | Absolute `/nix/store/...` path to the exported terminal output. |
| `tool_versions` | Versions observed by the release's built-in check. |

Define the identity record as an object containing `manifest` (all manifest fields except `release_id`) and `artifacts` (a filename-to-SHA-256 map for `nix-bootstrap.tar.xz`, `closure.nar`, and `bootstrap.sh`). Serialize with `jq -cS .`, including its final newline, and hash those bytes. Then insert the resulting hex digest into the manifest. This avoids a self-referential hash and makes the identity algorithm reproducible.

Use Nix's closure query/export to include every referenced store path, not merely a tar of `bin/`. For example, the export operation consumes the closure returned by `nix-store --query --requisites "$profile"` and passes all paths to `nix-store --export`.

Package the official x86-64 Nix 2.34.6 binary distribution, verifying its upstream checksum while building the release. Record that verification in the release build output. Do not download the bootstrap during cluster startup.

`SHA256SUMS` covers the manifest, bootstrap archive, closure, and bootstrap script. For unattended restoration, pin the expected SHA-256 of `SHA256SUMS` in the trusted init script. Checksums detect corruption; authenticity depends on the reviewed init script and restricted publication permissions. A checksum downloaded beside an arbitrary script is not a trust boundary.

### Runtime interface

The fixed deployment root is `/local_disk0/persephone`:

```text
/local_disk0/persephone/
  releases/<release-id>/
    manifest.json
    profile -> /nix/store/...
  current -> releases/<release-id>
  previous -> releases/<previous-release-id>
  user/
    config/
    data/
    state/
    cache/
  nix/                    bootstrap executables, config, state, GC roots
  enter                   stable entry point
```

Bootstrap command contract:

```bash
bash databricks/bootstrap.sh install "$RELEASE_DIR" "$SUMS_SHA256"
bash databricks/bootstrap.sh status
bash databricks/bootstrap.sh rollback
/local_disk0/persephone/enter
```

- `install`: verify the pinned checksum-file digest before trusting manifest fields; verify all listed files; reject unsupported format/architecture; restore bootstrap and closure; check candidate; activate.
- `status`: report active/previous release IDs and profile paths; fail distinctly if nothing is installed.
- `rollback`: validate the previous release, then activate it without downloading, rebuilding, or resolving dependencies. Fail without mutation if there is no previous release.
- `enter`: resolve the active release once, set isolated tool configuration/state locations, prepend its tools and pinned Nix to PATH, and execute Fish. It may forward `-c` commands for verification.
- Set `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`, and `NIX_USER_CONF_FILES` explicitly. Enable Nix's XDG layout and select a local store, not a daemon connection. Verify actual Nix writes, including the default-profile initialization path.
- Do not set cluster-wide PATH, `PYTHONPATH`, `JAVA_HOME`, `SPARK_HOME`, or `SHELL` as part of init. Any shell-specific setting belongs inside the launcher.
- Keep active and previous store closures GC-rooted. No automatic store garbage collection in the initial implementation.

### Activation semantics

Hold one installation lock across restore/activation/rollback. Prepare candidates in a bootstrap-owned staging directory and leave `current` unchanged until the candidate check succeeds. Commit `current` using an atomic same-filesystem symlink replacement. Prepare `previous` to reference the old active release before that commit; an interruption must leave an identifiable valid active release and must not advertise an unchecked candidate as active.

Reinstalling the current release is idempotent and does not destroy the previous rollback target. Failed checksum verification, failed import, or a failing candidate check leaves the active release unchanged. Do not reset or overwrite an existing Nix database; the bootstrap must coexist with the proof of concept or stop with an actionable incompatibility error before mutation.

New launchers use the newly active release. Existing shells/tmux servers are not killed; they may retain the old release. Root every launched release for the session lifetime or retain installed closures without GC, as required by the no-automatic-GC policy. Rollback restores release-managed packages and configuration, not mutable history or an external application's data schema.

After compute replacement, restore the explicitly pinned published release; do not assume local `previous` or mutable user state survives. Older published releases remain available for an explicit startup-release change.

## 5. Implementation tasks

### Task 1: Build and enter the pinned terminal environment

**Files:** Create `databricks/flake.nix`, `databricks/flake.lock`, `databricks/packages.nix`, and `databricks/config.nix`. Reuse `home-files/tmux/tmux.conf`. Update `README.md` with the local build/entry workflow after it works.

**Consumes:** Tested nixpkgs revision, explicit package list, existing tmux settings.

**Produces:** `packages.x86_64-linux.persephone` with `bin/enter` and `bin/check` and all runtime references retained in its closure.

- [ ] Define the flake with only the inputs actually used. Start with nixpkgs revision `035cdf085e9adbb965e6031d0d9d0c1ed2731480`; generate the lock without upgrading existing platform locks.
- [ ] Add the sorted package list from section 2.
- [ ] Generate configuration and launcher according to sections 2 and 4; require an explicit non-secret Git identity, and preserve direnv's normal per-directory approval boundary without automatically trusting project configuration.
- [ ] Implement `bin/check` to run Fish code that parses JSON with jq, search a temporary fixture with ripgrep/fd, select a supplied item with fzf's non-interactive filter, inspect effective Git configuration, and report tool versions. Isolate and remove its own fixture directory.
- [ ] Build and run the output on an x86-64 Linux builder:

  ```bash
  nix flake check ./databricks --no-update-lock-file
  nix build ./databricks#persephone --out-link /tmp/databricks-terminal-profile
  /tmp/databricks-terminal-profile/bin/check
  /tmp/databricks-terminal-profile/bin/enter
  ```

- [ ] In the interactive shell, open a file with Helix, create/split/exit a tmux session on the dedicated socket, and exercise fuzzy selection. Inspect Fish initialization for missing-command errors.
- [ ] Compare a disposable home directory before/after; prove configuration writes remain confined and exit leaves the parent shell environment unchanged. Do not use the developer's real home as a destructive test fixture.
- [ ] Record exercised checks and document the entry workflow. Make one scoped implementation commit after this task's acceptance gate passes.

**Acceptance:** Terminal behavior works, relevant familiar settings load, and no workstation or Databricks runtime configuration is imported or overwritten. Build checks alone do not establish interactive behavior.

### Task 2: Export and restore a complete release offline

**Files:** Create `databricks/release.sh` and the install/status portions of `databricks/bootstrap.sh`; create initial `databricks/tests/lifecycle.sh`. Update `README.md` with release format and restore commands after the smoke run.

**Consumes:** `persephone` output from Task 1; official pinned Nix binary distribution.

**Produces:** Immutable release directory and the `install`/`status` interfaces in section 4.

- [ ] Add an isolated lifecycle regression scenario that starts without `/nix`, imports a real release, and executes Fish/jq from the imported closure. Keep fixtures outside the developer's home and host store.
- [ ] Implement atomic release assembly, manifest generation, upstream bootstrap verification, closure export, and checksums. Include every bootstrap/check helper dependency or explicitly verify the base-image prerequisites before mutation.
- [ ] Implement offline single-user bootstrap with contained Nix configuration/state; do not run a general-purpose installer that edits root profiles or enables services.
- [ ] Handle both an absent local store and a compatible existing store. Verify conflicting existing store files instead of overwriting them; do not initialize a fresh database over the proof of concept's database.
- [ ] Run the real restore in a disposable root-capable x86-64 Linux VM/container with network disabled and a private `/nix` and `/local_disk0`. Do not bind-mount the host store.

  ```bash
  bash databricks/release.sh /tmp/databricks-terminal-releases
  # Inside the disposable target, RELEASE_DIR and SUMS_SHA256 identify
  # the completed, read-only-mounted release and its trusted digest.
  # Authenticate and verify the release before executing its bootstrap.
  printf '%s  %s\n' "$SUMS_SHA256" "$RELEASE_DIR/SHA256SUMS" | sha256sum --check --status
  (cd "$RELEASE_DIR" && sha256sum --check SHA256SUMS)
  bash "$RELEASE_DIR/bootstrap.sh" install "$RELEASE_DIR" "$SUMS_SHA256"
  bash "$RELEASE_DIR/bootstrap.sh" status
  /local_disk0/persephone/enter -c 'fish --version; jq -n "1 + 1"'
  ```

- [ ] Assert jq outputs `2`; confirm the active manifest matches the built profile; confirm no package downloads or source builds occurred.
- [ ] Check `/root` for default-profile/config changes and verify no Nix daemon service was added.
- [ ] Run the lifecycle scenario, document observed prerequisites, and commit the independently working release/restore path.

**Acceptance:** A fresh target runs the exported environment without Git, flake evaluation, a package cache, or network access. A compatible pre-existing Nix store remains usable.

### Task 3: Prove safe activation, failed-update behavior, and rollback

**Files:** Complete `databricks/bootstrap.sh`; extend `databricks/tests/lifecycle.sh`; update `README.md` with update/rollback behavior.

**Consumes:** Release/install contract from Task 2.

**Produces:** Atomic `current` activation, `previous` retention, `rollback`, installation locking, and GC roots.

- [ ] Create two real release fixtures with observably different managed configuration, rather than simply changing a manifest label.
- [ ] Add deterministic regression scenarios for A-to-B activation, B-to-A rollback, first-install rollback failure, idempotent reinstall, and preserving the prior generation when a candidate check fails.
- [ ] Add scenarios for a corrupt closure, unsupported architecture, competing installations, and interruption before activation. Assert active tool/configuration behavior remains from the valid release, not just that a symlink exists.
- [ ] Implement the state transitions and lock described in section 4. Keep the active release stable through failed checks/imports; never activate a partial candidate.
- [ ] Verify current and previous closures have GC roots and no automatic GC is run. Keep mutable user state separate from immutable release configuration.
- [ ] Run `bash databricks/tests/lifecycle.sh` in the disposable test environment, then manually enter B and rolled-back A to observe the configuration difference. Document that existing tmux servers retain their own environment.
- [ ] Update operating instructions and commit after the lifecycle gates pass.

**Acceptance:** Failed updates do not replace a working environment; rollback needs no network/build; repeated installation does not erase the rollback target; concurrent operations cannot interleave activation.

### Task 4: Exercise the release on dedicated Databricks compute

**Files:** Update `README.md` with the exercised deployment procedure and limitations. Change implementation files only for defects found in this new path.

**Consumes:** Release and lifecycle implementation from Tasks 1–3.

**Produces:** Evidence that the release works through the actual Databricks terminal surface without runtime damage.

- [ ] Confirm the intended workspace profile and cluster in the implementation session. The previous `DEFAULT`/cluster pair is historical context, not permission to start compute now.
- [ ] Read the current cluster configuration and policy. Check that the target is dedicated to one principal, x86-64, and compatible with driver-local installation; do not change its runtime, worker count, policy, or auto-termination setting.
- [ ] Inventory the proof of concept and existing store. Capture protected-file contents/hashes and the Databricks Python executable/environment before deploying the new release.
- [ ] Stage the verified release locally and perform manual restoration. Do not attach an init script yet.
- [ ] Connect through both SSH and the web terminal. Run `/local_disk0/persephone/enter`, exercise Fish/jq, edit a scratch file in Helix, use fzf, and create/split/exit a tmux session.
- [ ] Confirm no missing-library/terminal-capability errors. Verify root home configuration and system shell settings remain unchanged.
- [ ] Outside the entered shell, execute a small notebook smoke check:

  ```python
  import sys
  assert sys.executable == recorded_python_executable
  assert spark.range(3).count() == 3
  ```

  `recorded_python_executable` is the pre-install value captured in the same notebook context. Do not compare ephemeral Python paths across different cluster lifetimes.

- [ ] Exercise one release update and rollback through the same terminal. Record versions, release IDs, terminal observations, and protected-file/runtime comparisons.
- [ ] Document the observed result and any limitations; do not label restart restoration verified yet.

**Acceptance:** Actual SSH and web-terminal use works; Databricks runtime behavior and protected configuration remain intact; the existing proof of concept is not removed as incidental cleanup.

### Task 5: Restore the pinned release after compute replacement

**Files:** Create `databricks/init.sh`; update `README.md` with publication, attachment, restart, and recovery procedures.

**Consumes:** Verified release/bootstrap from Tasks 1–4 and an approved release-storage location.

**Produces:** Driver-only startup restoration of one explicitly pinned release.

- [ ] Select an existing approved Unity Catalog Volume with read permission for the cluster's assigned principal and restricted publisher write permission. Verify availability from init-script execution, not just from an interactive notebook. If no suitable Volume exists, obtain an approved persistent artifact location before enabling automation; do not create a catalog or invent storage credentials.
- [ ] Publish to a new versioned directory and verify the uploaded bytes. Never overwrite an existing release directory or point startup at a mutable `latest` release.
- [ ] Generate a small init script with the literal release directory and checksum-file digest. The driver guard is:

  ```bash
  #!/bin/bash
  set -euo pipefail
  if [[ "${DB_IS_DRIVER:-FALSE}" != "TRUE" ]]; then
    exit 0
  fi
  ```

  After the guard, use available base-image tools to verify the pinned digest and file checksums before executing the released bootstrap. Verify required base-image tools before mutation. Do not depend on a newly installed tool to authenticate the installer itself.

- [ ] Keep the init script below Databricks' 64 KB limit. Do not set global PATH/runtime variables; do not install anything on workers.
- [ ] Present the exact proposed cluster configuration change and startup-failure risk for approval. Preserve existing init-script order and settings; append only the terminal script where appropriate.
- [ ] With explicit approval, attach the script and restart/replace compute. Do not merely rerun the installer on the previously provisioned driver and call it a restart test.
- [ ] Confirm the pinned release restores from an initially absent terminal installation, then repeat the Task 4 terminal/runtime smoke checks. On a multi-node target, confirm worker logs show the guard skipped installation; do not resize a single-node cluster solely for this check.
- [ ] Document recovery: detach the terminal init script or repoint it to the previous known-good pinned release, then restart with approval. Do not suppress init-script errors to keep launch green.

**Acceptance:** New driver-local storage receives the same pinned environment without manual repair, builds, or external package fetches. Existing init scripts and Databricks runtime settings remain intact. Worker-skip evidence is reported only if actually exercised on workers.

## 6. Approved decisions and execution prerequisites

The following defaults are synchronized with the approved specification:

1. **Baseline tools:** the ten tools listed in section 2, plus the pinned Nix bootstrap. No agent is included without a subsequent explicit scope change.
2. **Configuration management:** Nix-generated files initially, not full Home Manager activation.
3. **Mutable state:** local and disposable; no promise that history, agent sessions, or authentication persists across replacement.
4. **Release distribution:** approved Unity Catalog Volume where supported; its concrete catalog/schema/volume is an implementation prerequisite, not something to fabricate in this plan.
5. **Startup behavior:** attached bootstrap failures fail cluster startup. Complete manual restoration and rollback proof before accepting that coupling.
6. **Target:** Nix machine target is `persephone`, with deployment root `/local_disk0/persephone`. The historical personal cluster is a candidate, not current authorization. Confirm profile/target before live work; do not rename the cluster or change its hostname implicitly.

Changes to these approved defaults require updating the specification and this plan before implementation. In particular, adding an agent or requiring durable user state changes package/configuration and storage acceptance criteria.

## 7. Completion checklist

- [ ] Source definitions and dependency pins are committed and reproducible.
- [ ] Terminal package/configuration closure builds outside Databricks.
- [ ] Fresh offline restore works without default-profile writes under root's home.
- [ ] Compatible existing Nix store is preserved.
- [ ] Interactive Fish, Helix, fzf, and tmux behavior is observed on the real target.
- [ ] Root/system configuration and Databricks Python/Spark behavior remain unchanged.
- [ ] Corrupt/failed/interrupted candidates cannot replace a working release.
- [ ] Update, idempotent reinstall, rollback, and concurrent-operation behavior are exercised.
- [ ] Active/previous closures are rooted; no automatic GC or implicit process termination.
- [ ] Approved restart restoration is observed on freshly provisioned driver-local storage.
- [ ] Driver-only behavior is verified to the extent the actual target permits; untested worker behavior is explicitly identified.
- [ ] README contains exercised build, publish, enter, update, rollback, and failed-startup recovery procedures.
- [ ] No standard/serverless support, durable-user-state support, or coding-agent inclusion is claimed without its own implementation and evidence.

## 8. Specification acceptance coverage

Acceptance IDs refer to section 9 of the [approved specification](../specs/2026-10-15-databricks-terminal-environment-design.md#9-acceptance-criteria). Coverage identifies future work, not completed verification.

| Spec criterion | Implementation task and evidence |
| --- | --- |
| A1 — external build and offline restore | Tasks 1–2: pinned build and real restore in a fresh, network-disabled target. |
| A2 — SSH and web-terminal usability | Tasks 1 and 4: interactive Fish, Helix, fzf, and tmux checks on the actual surfaces. |
| A3 — configuration and process isolation | Tasks 1–2 and 4: parent environment, protected-file comparisons, and absence of root default-profile/daemon side effects. |
| A4 — Databricks runtime preservation | Task 4: same-context Python executable/environment comparison and Spark count smoke check. |
| A5 — safe updates and failed candidates | Task 3: real distinguishable releases and corrupt/failing-candidate regression scenarios. |
| A6 — idempotence, concurrency, interruption | Task 3: lifecycle regression scenarios that assert active behavior and preserved rollback history. |
| A7 — offline rollback without process termination | Tasks 3–4: rollback and existing-session observations; no builds or network. |
| A8 — existing installation preservation | Tasks 2 and 4: compatible-store restoration and proof-of-concept inventory/comparison. |
| A9 — restoration after compute replacement | Task 5: approved fresh-driver restoration and repeated terminal/runtime checks. |
| A10 — worker skip | Task 5: driver guard and worker-log evidence only when a multi-node target is actually exercised. |
| A11 — exercised operating documentation | Tasks 1–5: README procedures updated after their respective smoke proofs. |

## 9. References

- [Cluster-scoped init scripts](https://learn.microsoft.com/en-us/azure/databricks/init-scripts/cluster-scoped): failed scripts prevent cluster launch; script size limit is 64 KB; dedicated access uses the assigned principal's identity.
- [Init-script environment variables](https://learn.microsoft.com/en-us/azure/databricks/init-scripts/environment-variables): `DB_IS_DRIVER` supports a driver-only guard.
- [Init-script recommendations and storage support](https://learn.microsoft.com/en-us/azure/databricks/init-scripts/): Unity Catalog Volumes recommended for Runtime 13.3 LTS and above with Unity Catalog; DBFS init scripts are end-of-life.
- Local repository context: `linux/flake.nix`, `linux/flake.lock`, `home.nix`, `packages.nix`, and `home-files/tmux/tmux.conf`.
