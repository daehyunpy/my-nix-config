# OMP Unity Gateway Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store Unity Gateway's Anthropic, OpenAI, Gemini, and open-model configuration in this repository's `home-files` directory, deploy through the existing Home Manager mechanism, and exercise each API family through OMP.

**Architecture:** `home-files/omp/models.yml` is the single non-secret provider registry. Root `home.nix` links it to `~/.omp/agent/models.yml` with the same out-of-store symlink helper as Zed. Four provider namespaces share command-backed authentication while keeping their API routes separate; mutable OMP preferences and resolved credentials are not managed by Nix.

**Tech Stack:** Nix flakes, Home Manager, OMP 18.10.4, Unity Gateway `ug` 0.2.0+79.g07b0a8b, YAML.

## Global Constraints

- The setup must reside under `home-files` and deploy the same way as existing tools.
- Deployment target: `linux#daehyun@charon`.
- Preserve the existing default model, `openai-codex/gpt-6.1-sol`.
- No Gore gateway, direct vendor-account setup, named profiles, default-model change, OMP/ug installation or upgrade, custom synchronization daemon, automatic model discovery, credential migration, or Zed agent edits.
- Never store resolved tokens in the repository, Nix expressions, Nix store, shell history, or verification output.
- Existing `~/.ucode` paths and `ucode/...` client headers are retained by Unity Gateway for compatibility; do not rename them.
- Preserve unrelated and concurrent user edits; do not stage or commit them.
- Read `docs/superpowers/specs/2026-10-15-omp-unity-gateway-design.md` for discovery evidence and the complete model inventory.
- Avoid permanent tests that merely assert YAML text or forwarding. Use real OMP smoke requests.
- Execute inline: this is one small configuration/deployment change, not independent implementation slices.

---

## File Map

| File | Action and responsibility |
| --- | --- |
| `home-files/omp/models.yml` | Create the complete non-secret registry. |
| `home.nix` | Add one `home.file` mapping; reuse `makeOutOfStore` and `homePathString`. |
| `README.md` | Extend the existing OMP section with deployment, authentication, and selectors after smoke verification. |
| `~/.omp/agent/models.yml` | Home Manager creates this symlink; do not write a separate machine-local registry. |
| `~/.omp/agent/config.yml` | Read only to preserve the current default. |

## Task 1: Add the Declarative Registry and Home Manager Mapping

**Files:**
- Create: `home-files/omp/models.yml`
- Modify: `home.nix`, inside `home.file`
- Verification: `nixfmt --check home.nix`; `nix-instantiate --parse home.nix`

**Interfaces:**
- Consumes: workspace `https://adb-425124470313726.6.azuredatabricks.net`, profile `adb-425124470313726`, existing `~/.local/bin/ug`, and live catalog observed during design.
- Produces: four `unity-*` providers available through the user-level registry after Home Manager activation.

- [x] **Step 1: Check deployment conflicts.**

Read the current `~/.omp/agent` directory and existing user `config.yml`. Neither `models.yml` nor `models.yaml` existed at design time. If one now exists, read and reconcile it; do not overwrite unrelated providers. Confirm that the default model has not been changed by another process.

- [x] **Step 2: Create `home-files/omp/models.yml`.**

```yaml
providers:
  unity-anthropic:
    api: anthropic-messages
    baseUrl: https://adb-425124470313726.6.azuredatabricks.net/ai-gateway/anthropic
    apiKey: '!databricks auth token --host https://adb-425124470313726.6.azuredatabricks.net --profile adb-425124470313726 --output json | jq -er .access_token'
    auth: apiKey
    authHeader: true
    headers:
      User-Agent: "ucode/0.2.0+79.g07b0a8b pi/1.0.4"
      x-databricks-use-coding-agent-mode: "true"
    models:
      - id: system.ai.claude-fable-5-1
      - id: system.ai.claude-opus-5-5
      - id: system.ai.claude-sonnet-5-5
      - id: system.ai.claude-haiku-5-5
  unity-openai:
    api: openai-responses
    baseUrl: https://adb-425124470313726.6.azuredatabricks.net/ai-gateway/codex/v1
    apiKey: '!databricks auth token --host https://adb-425124470313726.6.azuredatabricks.net --profile adb-425124470313726 --output json | jq -er .access_token'
    auth: apiKey
    authHeader: true
    headers:
      User-Agent: "ucode/0.2.0+79.g07b0a8b pi/1.0.4"
    models:
      - id: system.ai.gpt-6-1-sol
      - id: system.ai.gpt-6-astra
      - id: system.ai.gpt-6-luna
      - id: system.ai.gpt-6-sol
      - id: system.ai.gpt-5-6-luna
      - id: system.ai.gpt-5-6-sol
      - id: system.ai.gpt-5-6-terra
      - id: system.ai.gpt-5-5
      - id: system.ai.gpt-5-5-pro
      - id: system.ai.gpt-5-4
      - id: system.ai.gpt-5-4-mini
      - id: system.ai.gpt-5-4-nano
      - id: system.ai.gpt-5-3-codex
      - id: system.ai.gpt-5-2
      - id: system.ai.gpt-5-1
      - id: system.ai.gpt-5
      - id: system.ai.gpt-5-mini
      - id: system.ai.gpt-5-nano
      - id: system.ai.gpt-oss-120b
      - id: system.ai.gpt-oss-20b
  unity-google:
    api: google-generative-ai
    baseUrl: https://adb-425124470313726.6.azuredatabricks.net/ai-gateway/gemini/v1beta
    apiKey: '!databricks auth token --host https://adb-425124470313726.6.azuredatabricks.net --profile adb-425124470313726 --output json | jq -er .access_token'
    auth: apiKey
    authHeader: true
    headers:
      User-Agent: "ucode/0.2.0+79.g07b0a8b pi/1.0.4"
    models:
      - id: system.ai.gemini-4-argon
      - id: system.ai.gemini-3-8-flash
      - id: system.ai.gemini-3-7-flash
      - id: system.ai.gemini-3-6-flash
      - id: system.ai.gemini-3-5-flash
      - id: system.ai.gemini-3-5-flash-lite
      - id: system.ai.gemini-3-1-flash-image
      - id: system.ai.gemini-3-1-flash-lite
      - id: system.ai.gemini-3-1-pro
      - id: system.ai.gemini-3-flash
      - id: system.ai.gemini-3-pro-image
  unity-oss:
    api: openai-completions
    baseUrl: https://adb-425124470313726.6.azuredatabricks.net/ai-gateway/mlflow/v1
    apiKey: '!databricks auth token --host https://adb-425124470313726.6.azuredatabricks.net --profile adb-425124470313726 --output json | jq -er .access_token'
    auth: apiKey
    authHeader: true
    headers:
      User-Agent: "ucode/0.2.0+79.g07b0a8b pi/1.0.4"
    models:
      - id: system.ai.deepseek-v4-1-flash
      - id: system.ai.deepseek-v4-flash-0731
      - id: system.ai.glm-5-2
      - id: system.ai.glm-5-3
      - id: system.ai.glm-5-3-flash
      - id: system.ai.kimi-k3
```

This deliberately preserves the observed Unity Gateway Pi client metadata. It does not pretend to implement Pi's automatic token-refresh process. No model limits or pricing are invented.

- [x] **Step 3: Add one mapping to root `home.nix`.**

Inside `home.file`, insert:

```nix
".omp/agent/models.yml".source = makeOutOfStore "${homePathString}/.config/nix/home-files/omp/models.yml";
```

Do not manage the entire `~/.omp` directory; it contains mutable databases, preferences, and sessions. Do not modify `.omp/config.yml`.

- [x] **Step 4: Run Nix checks once after configuration edits.**

```bash
nixfmt --check home.nix
nix-instantiate --parse home.nix
```

Expected: successful exit codes. Parsing is syntax verification, not proof that Home Manager activation succeeds.

## Task 2: Build and Deploy Using Home Manager

**Files:**
- Consumes: `home.nix`, `linux/flake.nix`, `linux/flake.lock`, and `home-files/omp/models.yml`
- Deployment output: Home Manager generation and `~/.omp/agent/models.yml` symlink

**Interfaces:**
- Consumes: Task 1's non-secret registry and `home.file` mapping.
- Produces: the user registry loaded by existing OMP CLI and ACP launches.

- [x] **Step 1: Build without activating.**

```bash
home-manager build --flake ./linux#daehyun@charon --no-out-link --no-write-lock-file
```

Expected: activation package builds successfully without changing the lock file. The new YAML file is referenced by an out-of-store path string, not imported into the flake; it does not need staging for flake evaluation.

- [x] **Step 2: Inspect activation actions.**

```bash
home-manager -n switch --flake ./linux#daehyun@charon --no-write-lock-file
```

Expected: the planned `.omp/agent/models.yml` link and no unrelated destructive actions. Concurrent repository edits may produce other activation changes; do not hide those changes or overwrite conflicting user files. If unsafe, stop activation and report the exact conflict.

- [x] **Step 3: Activate through the normal tool.**

```bash
home-manager switch --flake ./linux#daehyun@charon --no-write-lock-file
```

Expected: a successful Home Manager activation. Do not manually create the user symlink as a replacement for deployment.

- [x] **Step 4: Observe the deployed link.**

```bash
readlink -f /home/daehyun/.omp/agent/models.yml
```

Expected: `/home/daehyun/.config/nix/home-files/omp/models.yml`.

## Task 3: Exercise All API Families and Document Observed Behavior

**Files:**
- Runtime input: deployed `~/.omp/agent/models.yml`
- Modify: existing OMP section in `README.md`
- No permanent test or temporary source files required

**Interfaces:**
- Consumes: Task 2's activated user registry and existing Unity Gateway authentication.
- Produces: actual OMP completion evidence for each of the four transports and usage documentation matching observed results.

- [x] **Step 1: Inspect registration.**

```bash
omp models find unity-
```

Expected: the configured provider/model selectors appear without YAML validation errors. Model listing does not prove authentication or inference.

- [x] **Step 2: Create an isolated probe directory.**

```bash
mktemp -d /tmp/omp-unity-smoke.XXXXXX
```

Use the returned directory as `cwd` for the following commands. Do not launch probes from this repository, where project approval policies and instructions would alter the scenario. Do not set `PI_CODING_AGENT_DIR`: the probe must exercise the actual deployed registry.

- [x] **Step 3: Exercise Anthropic Messages.**

```bash
omp --no-session --no-title --no-tools --no-extensions --no-skills --no-rules --no-lsp --max-time 90s --model unity-anthropic/system.ai.claude-haiku-5-5 -p 'Reply with exactly UNITY_OK and nothing else.'
```

Expected: a successful completion containing `UNITY_OK`, not an authentication or request-shape error.

- [x] **Step 4: Exercise OpenAI Responses.**

```bash
omp --no-session --no-title --no-tools --no-extensions --no-skills --no-rules --no-lsp --max-time 90s --model unity-openai/system.ai.gpt-5-4-mini -p 'Reply with exactly UNITY_OK and nothing else.'
```

Expected: a successful completion containing `UNITY_OK` through the configured `/codex/v1` route.

- [x] **Step 5: Exercise Google Generative AI.**

```bash
omp --no-session --no-title --no-tools --no-extensions --no-skills --no-rules --no-lsp --max-time 90s --model unity-google/system.ai.gemini-3-5-flash-lite -p 'Reply with exactly UNITY_OK and nothing else.'
```

Expected: a successful completion containing `UNITY_OK` with bearer authentication through `/gemini/v1beta`.

- [x] **Step 6: Exercise the additional-model route.**

```bash
omp --no-session --no-title --no-tools --no-extensions --no-skills --no-rules --no-lsp --max-time 90s --model unity-oss/system.ai.deepseek-v4-1-flash -p 'Reply with exactly UNITY_OK and nothing else.'
```

Expected: a successful completion containing `UNITY_OK` through `/mlflow/v1`. This verifies the Chat Completions transport assumption rather than relying on SDK metadata alone.

If a probe fails, investigate the actual credential or wire error and make a narrowly supported configuration correction. Do not remove a requested family, suppress errors, claim an unexercised fallback works, or print resolved credentials.

- [x] **Step 7: Extend the existing README OMP section.**

Replace the claim that all model/provider configuration is machine-local with a precise distinction: non-secret provider definitions are managed in `home-files/omp/models.yml`, while preferences and credentials remain in the user profile.

Add this subsection, adjusting verification wording only to match observed results:

```markdown
### Unity Gateway providers

`home-files/omp/models.yml` defines the Unity Gateway providers. Home Manager links it to `~/.omp/agent/models.yml`, using the same live-link convention as Zed. OMP preferences, sessions, and credential storage remain unmanaged.

Install Unity Gateway and the Databricks CLI separately and authenticate the configured workspace/profile. Requests resolve tokens with `databricks auth token` and `jq` against the same profile as Unity Gateway; no token is stored in this repository or Nix configuration. Calling the Databricks CLI directly avoids `ug auth-token` startup exceeding OMP's 10-second command timeout. Existing `~/.ucode` paths and client headers are compatibility names retained by Unity Gateway.

Deploy on this Linux machine:

\`\`\`sh
home-manager switch --flake ~/.config/nix/linux#daehyun@charon
\`\`\`

Select a model explicitly:

\`\`\`sh
omp --model unity-anthropic/system.ai.claude-opus-5-5
omp --model unity-openai/system.ai.gpt-6-1-sol
omp --model unity-google/system.ai.gemini-4-argon
omp --model unity-oss/system.ai.kimi-k3
\`\`\`

Use `/model` inside OMP to switch models. The existing default is not changed by installing these providers. The explicit model list is a snapshot; refresh it from `ug status` when gateway availability changes.

OMP caches successful command credentials for the process lifetime; explicit credential refresh and 401 recovery invalidate that cache. Unity Gateway's Pi background refresh loop and Claude's helper TTL are not configured here.
```

The escaped fence notation above represents ordinary Markdown fences in the README, not literal backslashes. After smoke verification, add the actual transport results without claiming all 41 models, image generation, long context, token-expiry recovery, tool use, or Zed GUI behavior were exercised.

- [x] **Step 8: Confirm the default remains unchanged and remove the empty probe directory.**

Read the user `config.yml`; confirm its default still matches the value observed before activation. Remove only the empty temporary directory created for this run with `rmdir`. Report any probe-created state instead of deleting unrelated files.

## Plan Self-Review

- All requested model families have explicit provider entries and one actual OMP transport probe.
- The only deployed configuration source is under `home-files`, with the existing root Home Manager helper.
- The mutable user preferences, databases, and credentials are not replaced or linked wholesale.
- The implementation uses Unity Gateway's existing Databricks authentication profile and direct Databricks CLI token retrieval; legacy upstream-managed paths and headers stay intact.
- No new runtime wrapper, token file, test scaffolding, installation, upgrade, automatic discovery, or default-model change is planned.
- Expected command outputs are acceptance criteria, not claimed observations. Record actual outcomes during execution.

## Execution Evidence

- `nixfmt --check home.nix` initially identified the new long assignment as unformatted. Running `nixfmt home.nix` formatted it, and `nix-instantiate --parse home.nix` succeeded.
- Home Manager build, activation preview, and switch succeeded for `linux#daehyun@charon`, without updating the flake lock.
- `readlink -f ~/.omp/agent/models.yml` resolved to `/home/daehyun/.config/nix/home-files/omp/models.yml`.
- `omp models find unity-` listed 41 models under the four configured providers.
- Initial OMP probes failed before inference because `ug auth-token` took 24.74 seconds, exceeding OMP's 10-second credential-command timeout. Its direct `databricks auth token` backend returned the same credential in 0.74 seconds; the configuration and plan were corrected to use that backend without persisting or displaying the token.
- After correction, each planned OMP probe returned `UNITY_OK`: Claude Haiku 5.5, GPT-5.4 Mini, Gemini 3.5 Flash Lite, and DeepSeek V4.1 Flash.
- User `modelRoles.default` remained `openai-codex/gpt-6.1-sol`.
- The README was updated, and the empty temporary probe directory was removed.

