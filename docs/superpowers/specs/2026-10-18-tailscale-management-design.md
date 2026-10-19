# Shared Home Manager Tailscale configuration and tailnet infrastructure

## Status

Design for user review. The user selected shared Home Manager tooling plus generic NixOS/nix-darwin service wiring, without a Poseidon-specific system file or full NixOS-WSL adoption. Implementation and live infrastructure changes are not authorized by this document alone.

## Goal

Manage Tailscale user-side tooling through the existing shared Home Manager configuration, its privileged daemon through a reusable system-service module, and tailnet-wide resources through OpenTofu. Preserve current network behavior, local preferences, authentication ownership, identities, and key protection during adoption.

Home Manager does not own the privileged daemon. Native NixOS and nix-darwin modules provide systemd and launchd integration around the same shared declaration. No full NixOS-WSL system adoption is required, and no Poseidon-specific service implementation is introduced.

This is the first infrastructure-management use case in the repository, not a mandate to build a generic infrastructure framework.

## Design decisions

- Home Manager owns the common user-side Tailscale tooling through the existing root `home.nix` and `packages.nix` pattern.
- OpenTofu and the official `tailscale/tailscale` provider own tailnet-wide resources.
- A generic system module declares Nix-managed daemon enablement and package selection using the native `services.tailscale` interface. Home Manager activation never installs a root service or starts a second user daemon.
- All three repo-configured machines are in scope.
- `poseidon` is the NixOS-WSL machine currently named `charon` in the Home Manager flake. No Poseidon-specific Tailscale module or NixOS system output is required.
- Rename the Home Manager configuration to `daehyun@poseidon`, without keeping a `charon` alias.
- Preserve current policy, DNS, routing, authentication ownership, key-expiry settings, security properties, node identities, and addresses during adoption. Do not automatically reenroll or replace device identities; surface any unavoidable identity change for an explicit migration decision.
- Keep user activation, native system-service activation, and OpenTofu application explicit. A normal Home Manager switch does not install or replace the privileged daemon.
- The user separately selected unattended Tailscale SSH from Muse to `daehyun` on Thales and Poseidon using tag-based identities. Treat this as an explicit policy/ownership extension, not a side effect of adoption; apply no unrelated access changes.

## PEP20 design principles

| Principle | Consequence |
| --- | --- |
| Explicit is better than implicit | Every resource has one declared owner; user environment, system services, and tailnet resources remain distinct. |
| Simple is better than complex | Reuse the existing Home Manager package list, native system-service modules, and official provider; no custom service framework. |
| Flat is better than nested | One shared system module, the existing shared user configuration, and one OpenTofu root; no dedicated Poseidon system configuration. |
| Readability counts | The package declaration is shared; observed host-specific network roles remain explicit preservation requirements, not hostname-based activation branches. |
| Practicality beats purity | Keep privileged VPN services separate from user configuration instead of forcing root service installation into Home Manager. |
| Errors should never pass silently | Failed service startup or a CLI that cannot reach its intended daemon is a visible integration failure, not a successful setup. |
| Refuse the temptation to guess | Inspect live settings before taking ownership; do not infer an OS declaration or reset daemon preferences. |
| One obvious way to do it | One active daemon per host and one management path per tailnet resource; installing user tooling must not start a second daemon. |

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

Peer visibility is not an authoritative inventory of all tailnet devices or settings. The initial CLI observations did not establish ACL contents, DNS resolver lists, route approvals, or another host's installation variant. The subsequent GUI inspection below establishes a more specific baseline without changing live configuration.

### Cua Driver inspection: preservation baseline

The user requested inspection through `cua-driver` and preservation of the current setup. Inspection used the running Tailscale app and the authenticated Safari admin console, with screenshots cross-checked against accessibility snapshots. Only navigation, read-only disclosures, and observation were performed: no preference toggles, policy edits, saves, approvals, client updates, enrollments, disconnects, or infrastructure applies.

#### Managed devices

| Property | `apollo` | `thales` | `poseidon` |
| --- | --- | --- | --- |
| Tailscale IPv4 | `100.73.130.74` | `100.94.134.124` | `100.68.77.38` |
| Device ID | `nMzngfCre621CNTRL` | `nrGyKDY9Dv11CNTRL` | `npByKx79tM11CNTRL` |
| OS hostname | `apollo` | `thales` | `poseidon` |
| Client version | `1.104.1` | `1.104.1` | `1.98.8` |
| Observed availability | Connected | Connected | Offline; last seen Oct 16 |
| Key expiry | Enabled; console says approximately three months remaining | Disabled | Disabled |
| Tailscale SSH | Not shown as enabled; no SSH endpoint reported | Enabled | Enabled; SSH endpoint reported on TCP 22 |
| Approved subnet routes | None exposed | `192.168.68.0/24`; none awaiting approval | None exposed |
| Exit-node approval | Not allowed | Allowed | Allowed |
| Automatic client updates reported | `false` | `false` | `false` |
| Release track | `stable` | `stable` | `stable` |
| Encrypted client state reported | `true` | `false` | `false` |

At inspection, all three managed machines were user-owned under the same account and had no displayed tags. The later Muse SSH extension explicitly changes ownership of Muse, Thales, and Poseidon; do not introduce tags on any other device as cleanup. The console showed ten machines total. Muse receives only the control-plane changes described in the extension, not a new machine configuration.

The console confirms `poseidon` already has both OS hostname and Tailscale name `poseidon`. Only the repository's `charon` configuration key needs renaming. The console's WSL kernel string supports the WSL observation but does not independently prove the distribution is NixOS; that remains user-confirmed until the system declaration is retrieved.

`apollo` currently reports encrypted client state. Do not remove its existing client until the Nix-managed daemon can retain equivalent supported key protection, or the user explicitly accepts the specific security change. Selecting generic service wiring does not waive this preservation gate.

Do not interpret available client updates as authorization to upgrade the running daemon. Review package versions and CLI/daemon compatibility before service migration; unrelated automatic updates are not part of adoption.

#### Apollo local preferences

The app's Settings window visibly showed:

- Allow incoming connections: enabled.
- Use Tailscale DNS settings: enabled.
- Use Tailscale subnets: enabled.
- Launch Tailscale at login: enabled.
- Hide Dock Icon: enabled; notifications: off.
- VPN On Demand: not enabled.
- Run as exit node: disabled.
- Allow local network access when using an exit node: unchecked.
- Tailnet Lock: not enabled.
- The app's device view showed the selected exit node as `None`.

Preserve incoming connectivity, DNS acceptance, subnet-route acceptance, and no selected or advertised exit node on `apollo`. Do not enable SSH, exit-node advertisement, VPN On Demand, or Tailnet Lock during adoption. The target daemon has no GUI; preserve networking and startup behavior through the native service, and do not describe GUI presentation options as equivalent daemon settings.

The final Settings snapshot reported no changes from the initial Settings snapshot. Remote local preferences on `thales` and `poseidon` remain uninspected; their control-plane settings above are not substitutes for their complete local daemon configuration.

#### Tailnet DNS and HTTPS

- Tailnet DNS suffix: `dingo-ratio.ts.net`; do not rename it.
- MagicDNS: enabled, using `100.100.100.100`.
- Global nameserver group: Cloudflare Public DNS, expanded to `1.1.1.1`, `1.0.0.1`, `2606:4700:4700::1111`, and `2606:4700:4700::1001`, in that displayed order.
- Override DNS servers: disabled. The console also displayed Local DNS settings.
- Search domains: only the automatically included `dingo-ratio.ts.net` was displayed.
- No restricted/split-DNS nameserver group was displayed.
- HTTPS certificate provisioning: enabled.

Preserve the distinction between accepting Tailscale DNS on a client and globally overriding local resolvers: the former is enabled on `apollo`, the latter is disabled in the tailnet. Do not enable nix-darwin's `overrideLocalDns` as a supposed MagicDNS prerequisite. Do not disable HTTPS provisioning, replace the resolver list, or add search domains.

#### Current policy

The JSON editor displayed the complete document through its closing brace. Its structural content was:

```json
{
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"]
    }
  ],
  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr": ["funnel"]
    }
  ]
}
```

The displayed document also contains explanatory SSH and Funnel comments. No `acls`, `grants`, `groups`, `tagOwners`, `autoApprovers`, or `tests` fields were present. Preserve the baseline during adoption; only the separately requested Muse SSH extension adds tag definitions, SSH rules, and SSH tests. Do not convert to grants or generate empty network-policy fields. Tailscale documents that omitting `acls` applies default allow-all behavior, whereas `"acls": []` denies all connections; inserting an empty list would break preservation.

The Funnel capability is permission, not proof that a device currently publishes a Funnel service. Do not create, delete, or infer a published service from this policy alone. Export the authoritative policy before implementation to retain its exact source, comments, and any concurrent changes.

#### Preservation priority

No live setup changes were authorized by the inspection. The generic Nix-managed service target does not permit changes to existing network roles, ownership, expiry settings, key protection, or external-device access. The separately requested Muse SSH extension is the explicit ownership/access exception described below. Revalidate the baseline before any future apply because the live tailnet can change independently of this spec.

## Requested extension: unattended Muse SSH

### Authorized behavior and selectors

The user requested Muse access to `daehyun@thales` and `daehyun@poseidon`, confirmed that it must work without periodic browser reauthentication, and selected tagged Tailscale SSH after reviewing the ownership tradeoff.

- Source: only `muse`, currently device ID `n3u5ATYqT411CNTRL`, Tailscale IPv4 `100.115.105.38`, authenticated under the same account as the servers.
- Destinations: only the existing Thales and Poseidon device records from the baseline.
- Local SSH username: `daehyun`. Do not grant unattended root or other-user access.
- Apply `tag:muse` only to Muse and `tag:muse-ssh-target` only to Thales and Poseidon. These are purpose-based identities, not labels on top of user ownership.
- Define the two tag owners as the existing tailnet account. Assigning either tag to another device would extend its permissions and requires a separate reviewed change.

The network already permits these connections because `acls` is omitted. Add SSH authorization, not a new narrow network ACL that would replace the default network access.

SSH `check` rules take precedence over matching `accept` rules, regardless of their position. Do not append an accept rule that still overlaps the existing user-based check rule and claim unattended access. With tagged identities, Muse no longer matches the user-based source selector; the new accept rule must match only Muse and the target tag.

### Proposed merged policy

The following is the structural target, not a claim that the live policy has been changed. Preserve the explanatory comments and any concurrent edits when merging with the authoritative export.

```json
{
  "tagOwners": {
    "tag:muse": ["r74pxy8dnm@privaterelay.appleid.com"],
    "tag:muse-ssh-target": ["r74pxy8dnm@privaterelay.appleid.com"]
  },
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"]
    },
    {
      "action": "check",
      "src": ["r74pxy8dnm@privaterelay.appleid.com"],
      "dst": ["tag:muse", "tag:muse-ssh-target"],
      "users": ["autogroup:nonroot", "root"]
    },
    {
      "action": "accept",
      "src": ["tag:muse"],
      "dst": ["tag:muse-ssh-target"],
      "users": ["daehyun"]
    }
  ],
  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr": ["funnel"]
    },
    {
      "target": ["tag:muse", "tag:muse-ssh-target"],
      "attr": ["funnel"]
    }
  ],
  "sshTests": [
    {
      "src": "tag:muse",
      "dst": ["tag:muse-ssh-target"],
      "accept": ["daehyun"],
      "deny": ["root", "nobody"]
    },
    {
      "src": "r74pxy8dnm@privaterelay.appleid.com",
      "dst": ["tag:muse", "tag:muse-ssh-target"],
      "check": ["daehyun", "root"]
    },
    {
      "src": "tag:muse",
      "dst": ["100.73.130.74"],
      "deny": ["daehyun", "root"]
    }
  ]
}
```

Keep the original own-device check rule for user-owned devices. The second rule retains check-mode access from the existing account's personal devices to the newly tagged devices. The added node attribute retains their previously inherited Funnel capability; it does not publish any Funnel service.

The negative SSH tests express the new automation rule's intended boundaries. They do not assert that Muse previously lacked check-mode access as root or to other owned devices.

### Explicit ownership consequences

Tagging replaces user authentication with a service identity. The three devices no longer participate as user-owned nodes in `autogroup:self`. Tagged sources can use Tailscale SSH only to tagged destinations, and cannot use SSH check mode. Therefore:

- Muse's new unattended access is limited to `daehyun` on the two targets; its previous user-based SSH paths do not remain automatically available.
- Thales/Poseidon-originated SSH to user-owned devices cannot be preserved by simply retaining the old rule. Inventory required outbound SSH before tagging; stop if a required path has no separately reviewed solution.
- User-identity-dependent features, including Taildrop, are not presumed equivalent after tagging. Review actual use before applying.
- Preserve device IDs, IPs, route approvals, DNS, and current expiry settings. Muse currently has key expiry enabled; Thales and Poseidon have it disabled. Do not reauthenticate merely to assign tags, because that can regenerate keys and disable expiry.
- Removing all tags is not a simple console rollback: restoring user ownership requires user authentication on the device. Confirm an independent recovery path for each device before changing it, including the currently offline Poseidon.

The selected tagged design authorizes the stated ownership transition, not arbitrary permission widening or unsupported claims of unchanged user-based behavior. If required existing behavior conflicts with tagged identities, surface that exact conflict before applying.

### Application order and proof

Keep this policy change separate from initial no-drift imports and daemon/package migration.

1. Export the current policy and device configuration. Inventory affected user-based access, key expiry, route approvals, and recovery methods.
2. Validate the merged policy with Tailscale's policy validator and SSH tests. Tag selectors in policy tests are not proof of actual device membership or working SSH sessions.
3. Apply the reviewed policy with both original check behavior and the tagged replacements present, then assign the target tag to the two existing server records through the control plane without reenrollment. Verify personal-account check-mode access after each available server transition.
4. Assign the source tag only to Muse, retaining its existing enabled key expiry. Confirm exact tag membership and the preserved device IDs, addresses, and expiry settings.
5. From Muse, exercise `ssh -o BatchMode=yes daehyun@thales` and `ssh -o BatchMode=yes daehyun@poseidon` with a harmless remote command and verify the remote username and hostname. Observe absence of a Tailscale check challenge; SSH batch mode alone does not establish that.
6. Verify the policy's root/other-user and unrelated-destination boundaries, personal check-mode access, preserved Funnel capability, and unchanged networking. Use policy tests for authorization denials rather than interpreting a timeout or offline server as a denial.

Do not mark the extension complete while Poseidon is offline, policy validation is unavailable, or only the document/JSON syntax has been checked. No live tags, policy changes, or successful Muse SSH sessions have been established by writing this spec.

## Scope and non-goals

### In scope

- A general Tailscale CLI package declaration using the existing shared Home Manager configuration, without a machine-specific module.
- One reusable system-service declaration imported by nix-darwin and the existing NixOS configuration, with compatible Home Manager tooling and no machine-specific module.
- The `charon` to `poseidon` Home Manager configuration-key rename and affected current commands and CI checks.
- Recording and preserving the observed host preferences, subnet routing, exit-node advertisement, and Tailscale SSH without applying one set of flags to every host.
- Adoption of existing tailnet policy, DNS settings, device tags, subnet/exit-route approvals, and preservation of existing per-device key-expiry settings where supported by the provider.
- Credential handling, OpenTofu state handling, adoption instructions, verification, and recovery instructions.
- The separately requested tag-based Muse SSH exception and its narrowly scoped ownership transition, with policy tests and preservation checks.

### Out of scope

- Replacing Tailscale with Headscale.
- Installing or changing client software on Windows, mobile, TV, Muse, or other machines outside the three managed hosts. Muse's specified control-plane tag and SSH policy changes are the sole exception.
- Migrating `poseidon` to another distribution or reinstalling WSL.
- Adopting the full NixOS-WSL system declaration, creating a Poseidon-specific system file or `nixosConfigurations` output, or changing users, boot settings, OS hostname, or WSL registration.
- Adding a second daemon through a Home Manager user service, silently changing private-state storage, or migrating device identities without an explicit decision.
- Installing root services through Home Manager activation scripts, automatically running sudo, or switching to userspace networking as a substitute for the current VPN.
- Redesigning access rules, enabling additional routes, changing key-expiry policy, or enabling SSH access beyond the explicitly requested Muse-to-two-targets exception.
- Combining Home Manager activation with NixOS activation as an unrelated migration.
- Automatically enrolling machines with repository-managed auth keys.
- Managing private node keys, login sessions, or macOS approval state as source-controlled configuration.
- Automatically applying infrastructure from CI, deploying a remote state service, or building a universal deployment wrapper.

The Windows/WSL topology remains unchanged. If inspection reveals a conflict, report it before service migration rather than silently disabling either client.

## Architecture and ownership

### Repository layout

```text
packages.nix
  Common Tailscale CLI package, alongside other shared CLI tools.

home.nix
  Existing shared Home Manager entry point; already imports packages.nix.
  No hostname-specific service logic or privileged activation hooks.

modules/tailscale.nix
  Shared system module: services.tailscale daemon enablement and package.
  Imported only in system-module contexts, never as a Home Manager module.

darwin/flake.nix
  Imports the shared system module through the existing common configuration.

linux/flake.nix
  Existing standalone Home Manager output, renamed to daehyun@poseidon.
  Exports the shared system module as nixosModules.tailscale for reuse.
  No new NixOS-WSL input or nixosConfigurations output.

infra/tailscale/
  OpenTofu provider configuration, imported resources, policy source,
  and the committed dependency lock file.
```

Update the existing README, validation workflow, and Git exclusions rather than creating a second set of operating conventions.

Do not create `linux/poseidon.nix`, adopt the complete WSL system, or populate the empty `nixos/flake.nix` as a new host entry point. The existing NixOS configuration imports the generic exported module; only its necessary Tailscale integration changes, with unrelated OS settings preserved. The module itself contains no hostname checks.

### Shared Home Manager layer

Use the existing root `home.nix` import of `packages.nix` for common tooling. Prefer that established package-list convention to introducing a new module or abstraction for one package. The declaration must be usable by another Home Manager user or host without referring to `poseidon`, `apollo`, or `thales`.

Home Manager installs the common CLI package, not `services.tailscale` system options. Generic native wiring supplies the privileged daemon separately; a user-only service or userspace networking is not an equivalent substitute for the existing VPN and exit-node roles.

Verify package compatibility and command resolution at each activation stage. Do not shadow a working App Store command with a CLI that cannot reach that backend. On macOS, coordinate the reviewed app-to-daemon cutover and Home Manager package activation rather than assuming the open-source CLI can control the App Store backend through a normal daemon socket.

Do not run `tailscale up`, `tailscale set`, logout, login, or daemon installation from Home Manager activation. Existing preferences intentionally differ between the workstation and routing servers. This shared configuration must not set all hosts to the same role.

### Generic system-service wiring

Use one reusable `modules/tailscale.nix` with the common `services.tailscale.enable` and `services.tailscale.package` declarations. Let the native modules supply systemd or launchd integration instead of writing unit files, launchd plists, or a custom installer.

Import it once from the common Darwin system configuration. Export it from the existing Linux flake as `nixosModules.tailscale`, and import that export into the already-running NixOS configuration. This is a reusable module interface, not `nixosConfigurations.poseidon` or adoption of its full system declaration. The import can be used by another NixOS host without editing this module.

Do not put exit-node advertisement, subnet prefixes, SSH enablement, usernames, or hostname-based branches into the shared defaults. Preserve those existing machine roles and any native option overrides. If a migration needs explicit preference restoration, use reviewed host-specific values in the native system context or the explicit migration procedure, not a bespoke Poseidon module or Home Manager activation hook.

Use compatible package selections between the user CLI and system daemon. The existing external NixOS configuration may use different package pins from standalone Home Manager; verify actual versions and supported interaction rather than assuming a shared package attribute means identical builds.

### Configuration-key rename, not system adoption

Rename the existing standalone Home Manager output from `daehyun@charon` to `daehyun@poseidon` and update its active CI and documentation callers. This naming correction does not require adopting the entire NixOS-WSL system declaration.

Inspect the active NixOS configuration only far enough to integrate the generic module safely and preserve current Tailscale overrides. Keep unrelated users, WSL defaults, boot settings, state versions, and services unchanged. Do not replace the system declaration with a guessed minimal configuration.

Keep the existing shared and Linux-specific Home Manager modules. Do not retain a deprecated `charon` alias. Keep historical design records as historical records rather than rewriting their deployment evidence.

Renaming the Home Manager output does not itself rename the OS, the Windows WSL registration, or a Tailscale device. Do not rename those identities unless live inspection shows a mismatch that requires an explicit migration decision.

### Tailnet layer

Use one OpenTofu root under `infra/tailscale/` with the official `tailscale/tailscale` provider. Select a verified provider release during implementation, constrain its version, and commit `.terraform.lock.hcl`.

Export current settings using authenticated read-only API access. Declare and import existing resources before applying changes. Treat policy and collection-valued settings as authoritative whole-resource ownership: omitting an existing rule, resolver, tag, or approved route must not accidentally remove it.

The initial inventory covers:

- The complete policy document, including existing grants or ACLs, groups, tag owners, SSH rules, auto-approvers, and embedded policy tests where present.
- MagicDNS, global and restricted nameservers, search paths, and other DNS settings supported by the selected provider that affect the existing configuration.
- Existing tags, ownership, per-device key-expiry settings, and subnet/exit-route approvals for the managed hosts.

Retain the policy in readable provider-supported source. First adopt the baseline unchanged; apply the separately reviewed Muse exception as a distinct policy/ownership change. Do not convert ACL style, introduce unrelated tags, or generate policy from peer visibility alone.

Device identity and mutable preferences belong to different layers. Nix owns what a host advertises; OpenTofu owns the corresponding control-plane approvals. Do not make OpenTofu re-enroll or destroy devices merely because a local installation changes.

### Credentials and state

Use a scoped Tailscale OAuth client for provider access, supplied through `TAILSCALE_OAUTH_CLIENT_ID` and `TAILSCALE_OAUTH_CLIENT_SECRET`. Supply the intended tailnet explicitly through `TAILSCALE_TAILNET`; confirm it matches the inventoried tailnet before import or apply. Grant only the scopes required by the adopted resources.

Creating the initial credential and performing interactive device login are bootstrap operations, not hardcoded repository resources. Do not generate reusable enrollment keys through OpenTofu for this change.

For the initial single-operator workflow, use local OpenTofu state and document its limitations. Ignore `.terraform/`, state and backup files, saved plans, and credential-bearing variable files; commit the provider dependency lock file. Do not put credentials, state, plans, or private device state into Nix expressions, the Nix store, Git, or verification output.

Back up state outside Git before import or apply and after successful adoption. Treat plans and backups as sensitive. Do not copy state between operators or run concurrent applies. A remote locking backend is a separate infrastructure decision, not silently introduced here.

## Migration and recovery

1. Revalidate and back up the Cua Driver baseline, local daemon preferences and private state, current tailnet configuration, and any OpenTofu state. Keep secret backups outside Git and the Nix store.
2. Rename the Home Manager key and update current documentation and CI references. Add the generic module export without creating a Poseidon system output or importing its full OS declaration into this repository.
3. Inspect existing native daemon ownership and configuration before adding the module import. Preserve unrelated system settings and existing Tailscale role overrides. Confirm independent recovery access before changing a host's VPN.
4. Evaluate both Darwin systems, the renamed standalone Home Manager output, and the generic NixOS module. Preview the actual existing NixOS system with its added import before activation; do not invent a replacement host configuration.
5. Configure provider credentials locally, validate the authoritative policy export, and import existing tailnet resources. Review the plan for no intended policy, DNS, ownership, expiry, or routing changes.
6. Migrate one available machine at a time using its native system activation. If its existing daemon is already Nix-managed, adopt it without unnecessary reinstall or reenrollment. Home Manager activation alone is not service activation.
7. Before replacing `apollo`'s App Store client, resolve the observed key-protection gate and required feature differences. Follow upstream client-removal and reboot guidance, and do not run both variants simultaneously. Keep the existing client unchanged if the gate cannot be satisfied.
8. Activate compatible Home Manager tooling, restore only the inventoried preferences that migration requires, and verify the intended daemon and network paths. Stop for an explicit decision if reenrollment would change the device identity.
9. Verify daemon startup after the planned native service restart and reboot or WSL distribution restart. Review the final OpenTofu plan for unexplained changes. An unavailable host remains explicitly unverified.

The selected design includes shared Home Manager tooling and generic native daemon management. It excludes full Poseidon system adoption and custom privileged Home Manager hooks. Completing only the CLI package declaration does not complete this design.

The headless macOS daemon has no menu-bar UI or macOS VPN-settings integration. Upstream documents limitations in consuming exit nodes and Taildrop support. No exit node was selected on `apollo` during inspection, but that does not establish that the user never uses those features. Surface any required unsupported behavior before changing the installed client; do not silently waive the preservation baseline.

Home Manager rollback covers user tooling; native system generations cover declared system configuration. Neither automatically restores removed App Store software, private keys, node identity, or tailnet API settings. Document previous-client recovery separately, back up state, and retain existing device records until a replacement has been explicitly approved and verified.

For NixOS-WSL, daemon startup means startup when the distribution runs; it does not promise availability while WSL is shut down or introduce Windows startup tasks.

Apply the Muse ownership/SSH extension only through its separate application sequence above. Do not combine tagging with OS client replacement or conceal its expected policy diff inside a no-drift adoption plan.

## Verification and acceptance criteria

### Static and evaluation checks

- Existing Nix formatting and evaluation checks pass for `apollo` and `thales`.
- `homeConfigurations."daehyun@poseidon"` evaluates; the obsolete `daehyun@charon` output is removed.
- Home Manager configuration contains only user-side options and no privileged activation hooks. Both Darwin systems import the generic native service declaration.
- `nixosModules.tailscale` evaluates in a disposable NixOS configuration and supplies the native daemon service. No production `nixosConfigurations` output or Poseidon-specific file is introduced.
- CI evaluates the renamed Home Manager output, existing Darwin systems, and generic NixOS service module without authenticated infrastructure applies. Evaluate the actual existing WSL system with the module import before its activation.
- OpenTofu formatting, initialization, and validation succeed with the committed provider lock file.
- Existing policy tests pass. Where policy tests are absent, verify concrete currently required permitted paths using supported policy validation and live traffic; do not invent denied-access requirements during adoption.
- Current README commands use the new output names. Historical records remain intact.

### Runtime proof

- Each migrated host runs exactly one intended Nix-managed daemon through its native service manager, and the Home Manager CLI reports that daemon's real authenticated status.
- Preserve device identity, local role preferences, and key protection through the reviewed daemon migration. Change authentication ownership only through the separately specified Muse tag transition. Verify startup after a service restart and planned reboot or WSL distribution restart.
- MagicDNS resolves real peer names and normal public DNS continues to work after user and system activation.
- Required peer connectivity is exercised with actual traffic, not inferred from successful evaluation or a daemon process listing.
- `thales` retains its required `192.168.68.0/24` subnet-routing behavior and exit-node advertisement. Verify subnet traffic from an authorized client that is not already on that subnet.
- `poseidon` retains its inventoried exit-node behavior while WSL is running. If Windows also runs Tailscale, resolve and verify the documented nested-tunnel risk before accepting the configuration.
- Verify exit-node traffic with a client that supports consuming exit nodes; do not select an exit node on `apollo` or assume a headless macOS client can consume one to perform the check.
- Existing enabled Tailscale SSH paths remain usable after native service migration and Home Manager activation. For the separate tag transition, verify the explicitly retained paths and review the documented user-identity limitations rather than claiming every former path is unchanged.
- The final OpenTofu plan has no unexplained changes. Reapplying machine configuration does not duplicate installations, re-enroll devices, or reset unrelated preferences.
- Credentials and private node state remain outside source-controlled and Nix-store content.
- Preserve the Cua Driver baseline: `apollo` accepts incoming connections, Tailscale DNS, and subnet routes without selecting or advertising an exit node; the tailnet DNS override stays off and HTTPS stays enabled.
- Preserve disabled key expiry on Thales and Poseidon, enabled expiry on Apollo and Muse, and personal check-mode access. Only the requested Muse extension introduces tags; never add an empty ACL/grant list.
- Preserve `apollo`'s reported encrypted-state protection before replacing its app. An unavailable equivalent protection is a migration blocker unless the user explicitly accepts the concrete security change.

A configuration that only evaluates or installs a CLI does not complete daemon adoption. If a host, native configuration import, preservation gate, or required API credential remains unavailable, report the exact unverified operation. Do not describe the privileged daemon as Home Manager-managed; it is managed by the generic native system module.

## Implementation prerequisites

These are concrete inputs required before the corresponding live changes, not values to guess:

- Access to each managed user's environment and native service configuration for preview, activation, and runtime verification. `poseidon` was offline during inspection. Its full system declaration need not be adopted, but its existing configuration must be accessible for a safe generic module import.
- Compatible CLI/system-daemon package selections and a staged macOS cutover plan that does not shadow the working App Store integration before its replacement is ready.
- Authenticated tailnet API access to export the authoritative policy, DNS, device settings, and approvals. The authenticated GUI baseline is recorded above but does not replace a current export before implementation.
- A supported plan preserving `apollo`'s key protection, or an explicit decision accepting a specific security change before client removal.
- Independent recovery access, backups, and activation previews showing only the reviewed Tailscale service changes and no unrelated OS changes.
- Before applying the Muse exception: authoritative policy validation, inspection of affected user-based access and feature use, recovery access to the tagged devices, and an available Poseidon for end-to-end proof.

Do not overwrite a running system declaration or replace tailnet policy with guessed defaults to bypass an unavailable prerequisite.

## Sources

- [PEP 20: The Zen of Python](https://peps.python.org/pep-0020/)
- [Tailscale: Manage resources using Terraform](https://tailscale.com/docs/integrations/terraform-provider)
- [Tailscale: macOS variants and migration cautions](https://tailscale.com/docs/concepts/macos-variants)
- [Tailscale: WSL 2 installation and simultaneous Windows/WSL limitations](https://tailscale.com/docs/install/windows/wsl2)
- [NixOS-WSL installation documentation](https://nix-community.github.io/NixOS-WSL/install.html)
- Local pinned nix-darwin source: `modules/services/tailscale.nix`, resolved through the repository's Darwin flake.
- [Tailscale ACL examples: omitted `acls` versus an empty list](https://tailscale.com/docs/reference/examples/acls)
- [Tailscale SSH: selectors and check-before-accept evaluation](https://tailscale.com/docs/features/tailscale-ssh)
- [Tailnet policy syntax: SSH rules and SSH tests](https://tailscale.com/docs/reference/syntax/policy-file)
- [Tailscale tags: identity, key expiry, and recovery limitations](https://tailscale.com/docs/features/tags)
