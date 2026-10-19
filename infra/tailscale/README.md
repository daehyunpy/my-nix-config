# Tailscale tailnet

OpenTofu root for the `dingo-ratio.ts.net` tailnet. Nix owns the CLI and the native daemon. This directory owns control-plane policy, DNS, key expiry, and route approvals. It does not enroll devices or install a daemon.

The default configuration is the inspected baseline. The Muse SSH change is a separate apply.

## Credentials

Create a Tailscale OAuth client and export:

```sh
export TAILSCALE_OAUTH_CLIENT_ID=...
export TAILSCALE_OAUTH_CLIENT_SECRET=...
export TAILSCALE_TAILNET=...
```

Confirm `TAILSCALE_TAILNET` is the inventoried tailnet before import or apply. Do not commit these values, state, or plans.

Baseline scopes:

- `policy_file`, plus the required `devices:posture_attributes` and `devices:core:read`
- `dns`
- `devices:routes`
- `devices:core` for key expiry and, only on the Muse apply, tags

`devices:core` asks for one or more tags on the credential. Confirm that credential can still read and update the existing user-owned devices before the baseline apply. Do not grant `all`.

## What is declared

| Resource | Baseline |
| --- | --- |
| Policy | `policy.baseline.hujson`: member SSH check, member Funnel attribute, no ACL or grant list |
| MagicDNS | enabled |
| Global nameservers | `1.1.1.1`, `1.0.0.1`, `2606:4700:4700::1111`, `2606:4700:4700::1001` |
| Apollo `nMzngfCre621CNTRL` | key expiry enabled, no approved routes |
| Thales `nrGyKDY9Dv11CNTRL` | key expiry disabled, `192.168.68.0/24`, exit-node routes `0.0.0.0/0` and `::/0` |
| Poseidon `npByKx79tM11CNTRL` | key expiry disabled, exit-node routes `0.0.0.0/0` and `::/0` |

Search paths, split DNS, HTTPS certificates, and the "override local DNS" toggle are not declared. The only observed search domain was the automatic `dingo-ratio.ts.net` suffix, no split-DNS group was displayed, HTTPS provisioning was enabled, and override DNS was disabled. Owning those with an empty or guessed value could remove them. Check each on the plan and in the console.

`policy.baseline.hujson` is the inspected structure. The console policy also had explanatory comments that were not captured verbatim. Replace that file with the authoritative export, comments included, before the first apply. Stop if the export contains rules this file does not.

Exit-node approval is represented as `0.0.0.0/0` and `::/0` because that is how provider 0.29.2 enables an exit node. Compare those sets with `GET /api/v2/device/:deviceID/routes` before apply. Stop if the live enabled set differs.

## Baseline apply

State is local. Copy it to a backup outside Git and the Nix store before import and after a successful apply. Do not run two applies at once.

```sh
tofu -chdir=infra/tailscale init
tofu -chdir=infra/tailscale plan -out=baseline.tfplan
```

Review the plan for no intended policy, DNS, ownership, expiry, or routing changes. Apply only that reviewed plan:

```sh
tofu -chdir=infra/tailscale apply baseline.tfplan
```

`tailscale_acl.policy` refuses to overwrite a tailnet that has not been imported, and destroying it does not reset the live policy. Device key and route resources use `prevent_destroy` because destroying them re-enables key expiry or clears approved routes. To stop managing one, run `tofu state rm` after recording the live value. Do not `tofu destroy`.

## Muse SSH apply

Leave `enable_muse_ssh` false until all of these are true:

- The baseline plan is empty.
- The authoritative policy validates with the merged `policy.muse.hujson` rules and SSH tests.
- Outbound SSH from Thales and Poseidon to user-owned devices is inventoried, and any required path has a reviewed replacement. Tagging removes `autogroup:self` for those devices.
- Taildrop and other user-identity features have been reviewed.
- Each device has a recovery path that does not depend on `tofu destroy`. Restoring user ownership requires logging in on the device.
- Poseidon is online.

Then:

```sh
tofu -chdir=infra/tailscale plan -var='enable_muse_ssh=true' -out=muse.tfplan
tofu -chdir=infra/tailscale apply muse.tfplan
```

This swaps in `policy.muse.hujson` and assigns `tag:muse` to Muse (`n3u5ATYqT411CNTRL`, expiry stays enabled) and `tag:muse-ssh-target` to Thales and Poseidon. It does not reenroll them. Do not combine it with a daemon migration.

After apply, from Muse:

```sh
ssh -o BatchMode=yes daehyun@thales
ssh -o BatchMode=yes daehyun@poseidon
```

Confirm the remote user and hostname, and that Tailscale does not issue a check challenge. The extension is not complete while Poseidon is offline.

## Nix activation

Home Manager installs the `tailscale` CLI only. `modules/tailscale.nix` enables the native `services.tailscale` daemon for nix-darwin and, through `linux#nixosModules.tailscale`, for an existing NixOS configuration. Do not import that module from Home Manager.

Activating the daemon is a separate `darwin-rebuild switch` or NixOS rebuild. A Home Manager switch does not enable it. The CLI package still ships the upstream `tailscaled` unit file in its profile; Home Manager does not link or start that unit. Do not run `tailscale up` from activation.

Pinned Nixpkgs provides Tailscale 1.98.10 for the shared CLI and both native daemon packages. Inspection recorded App Store client 1.104.1 on Apollo and Thales, and client 1.98.8 on Poseidon. Installing the shared CLI on Apollo can put this 1.98.10 binary ahead of the working App Store command. Do not run a Home Manager switch there until the App Store cutover is accepted. Do not treat the package pin as authorization to replace a running client.

Do not switch Apollo onto the Nix daemon until its App Store client can keep equivalent encrypted client state, or that specific loss is accepted. Do not run the App Store client and the Nix daemon together. Thales and Poseidon local daemon preferences were not inspected; preview the system diff and keep their current route, exit-node, and SSH advertisements. Poseidon's NixOS configuration is not in this repository. Import `nixosModules.tailscale` into that existing configuration and preview it there. Do not invent a replacement host.
