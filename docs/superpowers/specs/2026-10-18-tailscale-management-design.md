# Nix-managed Tailscale and tailnet infrastructure

## Status

Design for user review. The architecture was approved in conversation; implementation and live infrastructure changes are not authorized by this document alone.

## Goal

Make this repository the source of truth for Tailscale on `apollo`, `thales`, and `poseidon`, and for the tailnet-wide configuration managed through the Tailscale API. Adopt existing behavior first; do not combine adoption with access-policy redesign.

Use Nix-managed `tailscale` and `tailscaled` on macOS and Linux. Do not install the App Store app, the Homebrew GUI cask, or the Homebrew headless formula as part of the target configuration.

This is the first infrastructure-management use case in the repository, not a mandate to build a generic infrastructure framework.

## Approved decisions

- Nix owns machine installation and service configuration.
- OpenTofu and the official `tailscale/tailscale` provider own tailnet-wide resources.
- A shared Nix module declares the common Tailscale package and daemon enablement. Native platform modules own launchd and systemd integration.
- All three repo-configured machines are in scope.
- `poseidon` is the NixOS-WSL machine currently named `charon` in the Home Manager flake. It is not a new node or a distribution migration.
- Rename the Home Manager configuration to `daehyun@poseidon`, without keeping a `charon` alias.
- Preserve current policy, DNS, routing, identities where possible, and unrelated machine configuration during adoption.
- Keep machine activation and OpenTofu application separate and explicit.

## PEP20 design principles

| Principle | Consequence |
| --- | --- |
| Explicit is better than implicit | Every resource has one declared owner; user environment, system services, and tailnet resources remain distinct. |
| Simple is better than complex | Use existing Nix service modules and the official provider rather than custom API reconciliation. |
| Flat is better than nested | One shared machine module and one OpenTofu root; no speculative infrastructure framework or module hierarchy. |
| Readability counts | Host-specific routing and client preferences are visible in host configuration, not inferred from names. |
| Practicality beats purity | Share matching declarations without pretending launchd and systemd have identical interfaces. |
| Errors should never pass silently | Failed service startup, enrollment, preference application, import, or API access is visible and stops the affected operation. |
| Refuse the temptation to guess | Retrieve the existing NixOS-WSL declaration and live tailnet configuration before replacing either. |
| One obvious way to do it | One client installation per host and one management path per tailnet resource. |

## Discovery evidence and limits

Read-only inspection during design established:

- `darwin/flake.nix` defines `apollo` and `thales` with nix-darwin and Home Manager.
- `linux/flake.nix` currently defines only the standalone Home Manager output `daehyun@charon`. It does not declare a NixOS system.
- `nixos/flake.nix` is empty. There is no existing NixOS-WSL system declaration in this checkout.
- No Tailscale configuration or OpenTofu resource configuration was found in the repository. `packages.nix` already includes `tenv`.
- `apollo` has a running App Store Tailscale client. Its visible tailnet has MagicDNS enabled.
- From `apollo`, `thales` was online, advertised `192.168.68.0/24`, was available as an exit node, and advertised SSH host keys. Its local installation and settings have not been inspected.
- From `apollo`, `poseidon` appeared as a Linux node available as an exit node. SSH to `poseidon` timed out. Its current system declaration, daemon configuration, and Windows host configuration were not inspected.
- The user confirmed that `poseidon` runs NixOS-WSL.
- The pinned nix-darwin Tailscale module provides `services.tailscale.enable` and `services.tailscale.package`, installs the CLI, and creates a launchd daemon. It does not expose the same full preference interface as NixOS.

Peer visibility is not an authoritative inventory of all tailnet devices or settings. The CLI observations do not establish current ACL contents, DNS resolver lists, route-approval configuration, or the installation variant on another host.

## Scope and non-goals

### In scope

- Nix-managed headless Tailscale installation and service startup on the three named machines.
- Adoption of `poseidon`'s existing NixOS-WSL system declaration into the repository.
- The `charon` to `poseidon` Home Manager configuration-key rename and affected current commands and CI checks.
- Explicit, non-secret host preferences required to preserve existing connectivity, subnet routing, exit-node advertisement, and currently enabled Tailscale SSH.
- Adoption of existing tailnet policy, DNS settings, device tags, and subnet/exit-route approvals where present and supported by the provider.
- Credential handling, OpenTofu state handling, adoption instructions, verification, and recovery instructions.

### Out of scope

- Replacing Tailscale with Headscale.
- Installing or changing clients on Windows, mobile, TV, or other machines outside the three named hosts.
- Migrating `poseidon` to another distribution or reinstalling WSL.
- Redesigning access rules, enabling additional routes, creating new device roles, changing key-expiry policy, or enabling new SSH access during adoption.
- Combining Home Manager activation with NixOS activation as an unrelated migration.
- Automatically enrolling machines with repository-managed auth keys.
- Managing private node keys, login sessions, or macOS approval state as source-controlled configuration.
- Automatically applying infrastructure from CI, deploying a remote state service, or building a universal deployment wrapper.

If the existing Windows host conflicts with the WSL daemon, report the conflict and resolve the topology explicitly before activation. Do not silently disable or reconfigure the Windows client outside this scope.

## Architecture and ownership

### Repository layout

```text
modules/tailscale.nix
  Common daemon enablement and package selection.

darwin/flake.nix
  Imports the shared module for apollo and thales.
  Holds macOS-specific integration and host-specific settings.

linux/flake.nix
  Retains standalone Home Manager with the renamed daehyun@poseidon output.
  Adds the nixosConfigurations.poseidon system output and NixOS-WSL input.

linux/poseidon.nix
  Adopted NixOS-WSL system configuration and explicit host settings.

infra/tailscale/
  OpenTofu provider configuration, imported resources, policy source,
  and the committed dependency lock file.
```

Update the existing README, validation workflow, and Git exclusions rather than creating a second set of operating conventions.

The empty `nixos/flake.nix` is not populated as a competing entry point. Linux system and user outputs remain together in the existing Linux flake.

### Machine layer

The shared module uses the common `services.tailscale` interface. Select the package explicitly and consistently from each platform's pinned package set. This shares source declarations, not binaries; macOS and Linux still have their own builds and lock files.

Do not abstract differences in service managers or unsupported module options. Use native NixOS options where available. Where nix-darwin cannot express a required persistent client preference, use a narrowly scoped, explicit platform-specific application step derived from the declared host settings. Do not create a general service-management framework.

Client preferences must be inventoried before migration. Apply only explicitly owned preferences and preserve unrelated settings. Do not use a blanket reset or a `tailscale up` invocation that discards existing non-default preferences. Applying preferences must not create an endless activation wait or silently accept a failed command. Enrollment and preference application must be ordered after the daemon is available.

Adding a package through Home Manager alone does not satisfy system-service ownership.

### Poseidon system adoption

Retrieve the currently active NixOS-WSL declaration and its relevant imports and pins before constructing `nixosConfigurations.poseidon`.

Preserve its users, default WSL user, hostname, boot and WSL options, networking requirements, and `system.stateVersion`. Do not infer `system.stateVersion` from `home.stateVersion`, the current date, or a new channel version. Preserve secrets through appropriate external references rather than copying secret values into the repository.

Keep standalone Home Manager using the existing shared and Linux-specific home modules. Rename its output key and active callers; do not retain a deprecated alias. Keep historical design records as historical records rather than rewriting their deployment evidence.

Renaming the Home Manager output does not itself rename the OS, the Windows WSL registration, or a Tailscale device. Do not rename those identities unless live inspection shows a mismatch that requires an explicit migration decision.

### Tailnet layer

Use one OpenTofu root under `infra/tailscale/` with the official `tailscale/tailscale` provider. Select a verified provider release during implementation, constrain its version, and commit `.terraform.lock.hcl`.

Export current settings using authenticated read-only API access. Declare and import existing resources before applying changes. Treat policy and collection-valued settings as authoritative whole-resource ownership: omitting an existing rule, resolver, tag, or approved route must not accidentally remove it.

The initial inventory covers:

- The complete policy document, including existing grants or ACLs, groups, tag owners, SSH rules, auto-approvers, and embedded policy tests where present.
- MagicDNS, global and restricted nameservers, search paths, and other DNS settings supported by the selected provider that affect the existing configuration.
- Existing tags and subnet/exit-route approvals for the managed hosts.

Retain the policy in a readable provider-supported source file. Adopt its existing semantics; do not convert ACL style, invent tags, or create a policy from visible peer information.

Device identity and mutable preferences belong to different layers. Nix owns what a host advertises; OpenTofu owns the corresponding control-plane approvals. Do not make OpenTofu re-enroll or destroy devices merely because a local installation changes.

### Credentials and state

Use a scoped Tailscale OAuth client for provider access, supplied through `TAILSCALE_OAUTH_CLIENT_ID` and `TAILSCALE_OAUTH_CLIENT_SECRET`. Supply the intended tailnet explicitly through `TAILSCALE_TAILNET`; confirm it matches the inventoried tailnet before import or apply. Grant only the scopes required by the adopted resources.

Creating the initial credential and performing interactive device login are bootstrap operations, not hardcoded repository resources. Do not generate reusable enrollment keys through OpenTofu for this change.

For the initial single-operator workflow, use local OpenTofu state and document its limitations. Ignore `.terraform/`, state and backup files, saved plans, and credential-bearing variable files; commit the provider dependency lock file. Do not put credentials, state, plans, or private device state into Nix expressions, the Nix store, Git, or verification output.

Back up state outside Git before import or apply and after successful adoption. Treat plans and backups as sensitive. Do not copy state between operators or run concurrent applies. A remote locking backend is a separate infrastructure decision, not silently introduced here.

## Migration and recovery

1. Inventory and back up machine settings, current policy and DNS, existing approvals, and any existing state. Confirm local or otherwise independent access before changing the connection used to administer a host.
2. Retrieve and adopt `poseidon`'s current system declaration. Rename the Home Manager key and update current documentation and CI references.
3. Evaluate both Darwin systems, the renamed Home Manager output, and the new NixOS-WSL system without activation.
4. Configure provider credentials locally, validate the policy, and import the existing tailnet resources. Review the plan. Adoption must produce no intended access, DNS, or routing changes; investigate unexplained diffs before applying.
5. Cut over one machine at a time. Inventory the installed variant first. On `apollo`, remove the App Store client and follow the documented macOS cleanup/reboot procedure before starting the Nix daemon. Do not run two variants simultaneously.
6. Start the Nix-managed daemon, authenticate if required, and apply the reviewed host preferences. Do not promise that switching variants preserves node identity.
7. If reenrollment creates a new device identity, explicitly reconcile affected approvals and references with a reviewed OpenTofu plan. Do not delete the old device until its replacement is verified.
8. Verify connectivity and required host roles before touching the next machine. Review the final OpenTofu plan for drift.

The macOS target is deliberately headless. It has no menu-bar app or macOS VPN-settings integration. Current upstream documentation says this variant can advertise an exit node but cannot consume one, and Taildrop support is incomplete. The selected Nix-only architecture accepts these limitations. If inventory establishes an actively required unsupported feature, stop and surface the incompatibility rather than claiming full behavioral parity.

Nix generation rollback does not restore removed App Store software, OAuth credentials, device identities, or control-plane settings. Recovery instructions must distinguish package/service rollback, previous-client restoration, and reapplication of a saved tailnet configuration. Preserve the old device record until replacement verification is complete.

NixOS-WSL daemon startup means startup when the WSL distribution runs; it does not promise that the distribution starts with Windows or remains available when WSL is shut down. Preserve existing Windows startup behavior; do not add a Windows scheduled task as an implicit side effect.

## Verification and acceptance criteria

### Static and evaluation checks

- Existing Nix formatting and evaluation checks pass for `apollo` and `thales`.
- `homeConfigurations."daehyun@poseidon"` evaluates; the obsolete `daehyun@charon` output is removed.
- `nixosConfigurations.poseidon` evaluates with the adopted NixOS-WSL declaration and shared Tailscale module.
- CI evaluates the renamed Home Manager output and new Linux system output. No authenticated infrastructure apply runs in CI.
- OpenTofu formatting, initialization, and validation succeed with the committed provider lock file.
- Existing policy tests pass. Where policy tests are absent, verify concrete currently required permitted paths using supported policy validation and live traffic; do not invent denied-access requirements during adoption.
- Current README commands use the new output names. Historical records remain intact.

### Runtime proof

- Each managed host runs one intended Tailscale daemon, backed by the declared Nix package and its native service manager.
- After service restart, and after a planned reboot or WSL distribution restart, the daemon returns to the intended authenticated state without manual service startup.
- MagicDNS resolves real peer names and normal public DNS continues to work on the migrated hosts.
- Required peer connectivity is exercised with actual traffic, not inferred from successful evaluation or a daemon process listing.
- `thales` retains its required `192.168.68.0/24` subnet-routing behavior and exit-node advertisement. Verify subnet traffic from an authorized client that is not already on that subnet.
- `poseidon` retains its inventoried exit-node behavior while WSL is running. If Windows also runs Tailscale, resolve and verify the documented nested-tunnel risk before accepting the configuration.
- Verify exit-node traffic from a client that supports consuming exit nodes; a headless macOS daemon is not that client.
- Existing Tailscale SSH paths that are actually enabled remain usable after migration.
- The final OpenTofu plan has no unexplained changes. Reapplying machine configuration does not duplicate installations, re-enroll devices, or reset unrelated preferences.
- Credentials and private node state remain outside source-controlled and Nix-store content.

A configuration that only evaluates is not a completed adoption. If a host or required credential remains unavailable, report that host or tailnet operation as unverified rather than claiming the full migration succeeded.

## Implementation prerequisites

These are concrete inputs required before the corresponding live changes, not values to guess:

- Access to `poseidon`'s current NixOS-WSL declaration, relevant imports and pins, and system-service configuration. SSH was unreachable during design.
- Read-only inventory of `thales`'s installed variant and both Macs' relevant persistent client preferences.
- Authenticated tailnet API access to export policy, DNS, tags, and approvals. Local client status does not provide this full inventory.
- Inspection of whether `poseidon`'s Windows host also runs Tailscale.
- Independent recovery access for macOS client removal and any reenrollment.

Do not overwrite a running system declaration or replace tailnet policy with guessed defaults to bypass an unavailable prerequisite.

## Sources

- [PEP 20: The Zen of Python](https://peps.python.org/pep-0020/)
- [Tailscale: Manage resources using Terraform](https://tailscale.com/docs/integrations/terraform-provider)
- [Tailscale: macOS variants and migration cautions](https://tailscale.com/docs/concepts/macos-variants)
- [Tailscale: WSL 2 installation and simultaneous Windows/WSL limitations](https://tailscale.com/docs/install/windows/wsl2)
- [NixOS-WSL installation documentation](https://nix-community.github.io/NixOS-WSL/install.html)
- Local pinned nix-darwin source: `modules/services/tailscale.nix`, resolved through the repository's Darwin flake.
