# OMP Unity Gateway Multi-Family Provider Design

## Goal

Configure Anthropic, OpenAI, Google Gemini, and the other model families exposed by the Unity Gateway workspace in OMP. Manage non-secret configuration in this Nix repository, deploy through Home Manager, and verify each configured API family with an actual OMP request.

## Selected architecture

Use one user-level `models.yml` registry with four explicit provider namespaces. All four use the same workspace and command-backed credentials, but each selects its own API transport and endpoint. Do not force every model through Anthropic Messages or introduce named profiles.

Preserve the existing default, `openai-codex/gpt-6.1-sol`. Users select a gateway model through `/model` or an exact `--model provider/model-id` selector. Existing providers and Zed's `omp acp` integration remain unchanged.

## Discovery evidence

`ug status` returned a live authenticated model catalog on 2026-10-15. The workspace is `https://adb-425124470313726.6.azuredatabricks.net`, with CLI profile `adb-425124470313726`.

Transport metadata was inspected without exposing credentials in:

- `~/.ucode/pi-home/.pi/agent/models.json`: Anthropic Messages, OpenAI Responses, and Google Generative AI transports, their complete base URLs, and bearer-header configuration.
- `~/.ucode/opencode-xdg/opencode/opencode.json`: the additional open-model provider, its OpenAI SDK integration, model IDs, and MLflow endpoint.
- `~/.claude/ucode-settings.json`: the existing credential helper and coding-agent header.

Live discovery lists Haiku 5.5 rather than the older Haiku 4.5 in Claude's saved configuration. Use current model IDs, not the stale Claude list. The live catalog advertises 41 distinct model IDs across the four families. Discovery is evidence of advertised availability, not proof that every model accepts a completion from OMP.

`ug export` cannot supply a managed configuration: this workspace is self-configured. Do not depend on that command in the implementation.

### Current project identity

The current project is [Databricks Unity Gateway](https://github.com/databricks/unity-gateway), with CLI command `ug` and distribution name `unity-gateway`. This machine already has that distribution installed: `ug` resolves into `~/.local/share/uv/tools/unity-gateway/bin/ug`, and installed metadata reports version `0.2.0+79.g07b0a8b`. Its installation provenance still names the historical `databricks/ucode` Git URL.

Upstream retains the `ucode` command, Python package, and `~/.ucode` configuration paths for compatibility. These existing paths are not evidence that this machine needs reinstalling or migrating. Use Unity Gateway naming for new OMP provider IDs and documentation, but preserve the existing authentication profile, generated filenames, and observed client headers. Renaming those legacy artifacts would break integration rather than modernize it.

The verified CLI name remains `ug`. Authentication uses the same workspace-scoped Databricks CLI profile; execution established that calling its `databricks auth token` backend directly is required to stay within OMP's credential-command timeout. The observed `/ai-gateway/anthropic`, `/ai-gateway/codex/v1`, `/ai-gateway/gemini/v1beta`, and `/ai-gateway/mlflow/v1` routes do not change merely because the project was renamed. Do not install, upgrade, or reconfigure Unity Gateway as part of a naming correction.

### Unexpected CLI side effect

`ug --dry-run pi` performed authentication, reported saving the Databricks CLI profile, and printed a Pi launch message instead of printing configuration as its help promised. This was reported. Do not reuse it as a supposedly side-effect-free planning or verification command. No OMP configuration was deployed by this investigation.

## Provider boundaries

All paths below are relative to the workspace origin.

| OMP provider | Model families | OMP API | Base URL path |
| --- | --- | --- | --- |
| `unity-anthropic` | Claude | `anthropic-messages` | `/ai-gateway/anthropic` |
| `unity-openai` | GPT, GPT OSS | `openai-responses` | `/ai-gateway/codex/v1` |
| `unity-google` | Gemini | `google-generative-ai` | `/ai-gateway/gemini/v1beta` |
| `unity-oss` | DeepSeek, GLM, Kimi | `openai-completions` | `/ai-gateway/mlflow/v1` |

The first three API mappings are explicit in the existing Pi configuration. The MLflow route is exposed through an OpenAI SDK integration; standard Chat Completions is the initial transport choice, to be exercised directly before declaring support. Do not claim a successful SDK configuration inspection proves wire compatibility.

Separate providers avoid accidental route sharing, keep model selectors readable, and allow independent protocol compatibility settings if a real request establishes a need.

## Model inventory

Populate explicit model entries from the observed live catalog. Do not invent context windows, output limits, pricing, or image-generation capabilities. Image-named Gemini variants are catalog entries; their presence does not prove OMP image generation works through this gateway.

### `unity-anthropic`

- `system.ai.claude-fable-5-1`
- `system.ai.claude-opus-5-5`
- `system.ai.claude-sonnet-5-5`
- `system.ai.claude-haiku-5-5`

Use the live model IDs without adding Claude Code's `[1m]` suffix. Extended context is not part of this change; a short completion does not establish a one-million-token capacity.

### `unity-openai`

- `system.ai.gpt-6-1-sol`
- `system.ai.gpt-6-astra`
- `system.ai.gpt-6-luna`
- `system.ai.gpt-6-sol`
- `system.ai.gpt-5-6-luna`
- `system.ai.gpt-5-6-sol`
- `system.ai.gpt-5-6-terra`
- `system.ai.gpt-5-5`
- `system.ai.gpt-5-5-pro`
- `system.ai.gpt-5-4`
- `system.ai.gpt-5-4-mini`
- `system.ai.gpt-5-4-nano`
- `system.ai.gpt-5-3-codex`
- `system.ai.gpt-5-2`
- `system.ai.gpt-5-1`
- `system.ai.gpt-5`
- `system.ai.gpt-5-mini`
- `system.ai.gpt-5-nano`
- `system.ai.gpt-oss-120b`
- `system.ai.gpt-oss-20b`

### `unity-google`

- `system.ai.gemini-4-argon`
- `system.ai.gemini-3-8-flash`
- `system.ai.gemini-3-7-flash`
- `system.ai.gemini-3-6-flash`
- `system.ai.gemini-3-5-flash`
- `system.ai.gemini-3-5-flash-lite`
- `system.ai.gemini-3-1-flash-image`
- `system.ai.gemini-3-1-flash-lite`
- `system.ai.gemini-3-1-pro`
- `system.ai.gemini-3-flash`
- `system.ai.gemini-3-pro-image`

### `unity-oss`

- `system.ai.deepseek-v4-1-flash`
- `system.ai.deepseek-v4-flash-0731`
- `system.ai.glm-5-2`
- `system.ai.glm-5-3`
- `system.ai.glm-5-3-flash`
- `system.ai.kimi-k3`

## Authentication and request metadata

Each provider uses this credential reference:

```yaml
apiKey: '!databricks auth token --host https://adb-425124470313726.6.azuredatabricks.net --profile adb-425124470313726 --output json | jq -er .access_token'
auth: apiKey
authHeader: true
```

The command uses `databricks` and `jq` from OMP's `PATH`, keeping the shared configuration independent of Linux/macOS home paths. Execution measured `ug auth-token` at 24.74 seconds, exceeding OMP's 10-second timeout. Its direct Databricks CLI backend returned the same token in 0.74 seconds. This bypasses slow launcher startup, not Unity Gateway authentication. Tokens must never be embedded in Nix, committed files, logs, or command arguments. Installing or upgrading `ug` is not part of this work.

Preserve observed non-secret Unity Gateway client metadata for each transport, reading only selected non-secret header fields from its existing generated configuration. Existing `ucode/...` User-Agent values are client metadata, not OMP provider IDs; do not rewrite them without a verified replacement. Retain `x-databricks-use-coding-agent-mode: "true"` for Anthropic, as present in Claude's setup. Do not copy resolved Authorization headers out of generated tool configurations.

OMP resolves command credentials on demand, with a documented 10-second timeout and process-lifetime success cache. Explicit credential refresh and 401 recovery invalidate that cache. Claude's helper TTL and Pi's background refresh loop are not OMP settings and must not be advertised as implemented here.

On authentication failure, report the real error; do not fall back silently to an unrelated provider. Do not add global Anthropic environment variables, custom retries, strict-tool suppression, or experimental-beta suppression without a concrete compatibility failure.

## Repository integration

| File | Responsibility |
| --- | --- |
| `home-files/omp/models.yml` (new) | Four provider definitions, command credential references, headers, and explicit model IDs. |
| `home.nix` (modify) | Link the user registry through the existing out-of-store symlink convention. |
| `README.md` (modify) | Extend the existing OMP section with prerequisites, selectors, deployment, and verified limitations. |
| `~/.omp/agent/config.yml` (unchanged) | Retain mutable user preferences and the existing default model. |
| `.omp/config.yml` (unchanged) | Retain the project-local approval and LSP settings. |

Add this shared Home Manager entry:

```nix
".omp/agent/models.yml".source = makeOutOfStore "${homePathString}/.config/nix/home-files/omp/models.yml";
```

Shared configuration is available on Linux and macOS; actual requests require `databricks` and `jq` on OMP's `PATH` and the authenticated Unity Gateway Databricks profile. This deployment targets `linux#daehyun@charon` only. Preserve unrelated and concurrent repository changes, including the existing terminal-environment plan.

## Deployment and verification requirements

1. Reinspect the user registry immediately before deployment. If a registry has appeared since inspection, reconcile it rather than overwrite unrelated providers.
2. Validate changed Nix syntax and formatting, build the Home Manager activation package, and inspect activation actions before switching.
3. Account for new untracked files being omitted by Git-backed flake evaluation; use a path flake source if needed rather than staging unrelated user changes.
4. Activate `daehyun@charon` through Home Manager. If unrelated destructive activation actions appear, report the exact conflict instead of overwriting user files.
5. Confirm the deployed registry resolves to the repository file and OMP lists all four configured providers without configuration errors.
6. Run isolated, no-tools, no-session, no-title OMP requests from a temporary working directory against:
   - `unity-anthropic/system.ai.claude-haiku-5-5`
   - `unity-openai/system.ai.gpt-5-4-mini`
   - `unity-google/system.ai.gemini-3-5-flash-lite`
   - `unity-oss/system.ai.deepseek-v4-1-flash`
7. Use a trivial exact-output prompt and observe a real streamed completion for each transport. Investigate protocol errors on their actual route; do not silently omit a requested family.
8. Confirm the existing default remains unchanged and update the README with the observed supported paths and credential-refresh caveat.

No permanent tests that merely assert copied YAML or forwarding. Listing alone is not proof of inference. Smoke requests cover the four transports, not every advertised model, long context, token-expiry recovery, tool calling, image generation, or the Zed GUI.

## Non-goals

No Gore gateway, direct vendor-account setup, named profiles, default-model change, OMP/ug installation or upgrade, custom synchronization daemon, automatic model discovery, credential migration, or Zed agent edits. Model-list refresh remains an explicit configuration maintenance operation; use the live Unity Gateway catalog as evidence when updating it.

## Deployment result

Implemented under `home-files/omp/models.yml` and deployed through the root Home Manager mapping. Home Manager build, activation preview, and switch succeeded. The deployed user registry resolves to `/home/daehyun/.config/nix/home-files/omp/models.yml`, and OMP listed all 41 configured models.

All four planned OMP smoke requests returned `UNITY_OK`: Claude Haiku 5.5, GPT-5.4 Mini, Gemini 3.5 Flash Lite, and DeepSeek V4.1 Flash. This establishes working Anthropic Messages, OpenAI Responses, Google Generative AI, and MLflow Chat Completions paths. The default model remains `openai-codex/gpt-6.1-sol`. No credential values were written to the repository, and the empty temporary probe directory was removed.
