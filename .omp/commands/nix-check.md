---
description: Check Nix formatting and syntax without activating a configuration
argument-hint: "[Nix file paths or validation scope]"
---
Validate this repository's Nix configuration. Requested scope: $ARGUMENTS

- Use the requested scope; otherwise check Nix files changed in the current task. If there are no task changes, discover and check all non-empty `.nix` files. The empty `nixos/flake.nix` is a reserved placeholder, not a working flake.
- Run `nixfmt --check` and `nix-instantiate --parse` for each selected file. These are checks: do not rewrite files. Parsing checks syntax only, not module options or package availability.
- For semantic validation explicitly requested by the user, inspect `linux/flake.nix` or `darwin/flake.nix` for the actual output names. There is no root flake. Evaluate the relevant activation package or system derivation with `nix eval --raw --no-write-lock-file` and the appropriate `.drvPath` attribute; explain any missing inputs, network access, or platform limitations. Do not update lock files or claim a derivation evaluation is a successful build.
- Do not run `switch`, activate a generation, update flake inputs, or install packages as part of validation.
- Report the checked files, commands, failures, and any semantic/build checks not performed. Do not inspect `.env`, authentication databases, or private SSH material.
