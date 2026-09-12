# Agent instructions

This repository is the chezmoi source directory for the operator's macOS and
Omarchy/Linux machines. Read this file before changing files here.

## Safety and approval

- Do not modify, commit, or push changes without explicit user approval.
- After approval, make the smallest coherent change, show the resulting diff,
  and run the relevant checks before committing.
- Never put machine-private values (LAN addresses, tokens, host-specific paths,
  or credentials) in tracked files. Store them in the machine-local chezmoi
  config (`chezmoi edit-config`) or in an age-encrypted source file.
- Do not run `chezmoi apply`, install packages, restart services, or change
  remote state unless the user asked for that operation.

## Repository model

Chezmoi source names encode the target path and file attributes:

- `dot_foo` targets `~/.foo`.
- `private_` sets private permissions; `executable_` sets executable mode.
- `encrypted_...age` is decrypted by chezmoi with the age identity configured
  in `.chezmoi.toml.tmpl` (`~/.ssh/main`).
- `*.tmpl` files are rendered with persistent machine data from
  `~/.config/chezmoi/chezmoi.toml`; that local file is not this Git repository.
- `.chezmoidata/` contains shared, non-secret declarations. Do not add a
  private machine value there merely because a template needs it.

The root `README.md`, `AGENTS.md`, `.github/`, and `docs/` are repository
material and are ignored by `.chezmoiignore`; they are not installed into the
home directory.

## Ownership boundaries

Use the existing manager instead of adding a second installation path:

| Concern | Source of truth |
| --- | --- |
| macOS Homebrew formulas/casks/MAS apps | `.chezmoidata/homebrew.yaml` and the generated Brewfile |
| Portable pinned CLI binaries | `private_dot_config/aquaproj-aqua/aqua.yaml` |
| Language runtimes and selected runtime tools | `private_dot_config/mise/config.toml.tmpl` |
| Fish plugins | `private_dot_config/private_fish/fish_plugins.tmpl` and Fisher script |
| Herdr binary | Aqua manifest (`herdrdev/herdr`) |
| Herdr plugins | `.chezmoidata/herdr.yaml` only; never edit generated plugin state by hand |
| Herdr/Collie configuration | `private_dot_config/herdr/` |
| Omarchy packages/firewall/input setup | `.chezmoidata/omarchy.yaml` and numbered Omarchy scripts |
| Encrypted credentials/configuration | `encrypted_` source files plus the existing age identity |

Herdr plugin refs are updated by the scheduled `update-versions.yml` workflow.
Do not bump those refs manually unless the user explicitly asks for an
exception.

## Template and script rules

- Keep platform and profile branches explicit. macOS and Omarchy are not
  interchangeable; Omarchy's `/usr/share/omarchy` belongs to the distro.
- Preserve the numbered `run_*` script ordering and the repository's numbered
  step log format. Scripts must be idempotent and safe to rerun.
- Remember that `run_onchange_` scripts rerun when their own rendered content
  changes; deletion of an installed artifact does not trigger them.
- Prefer capability detection and existing distro helpers over assuming a
  package manager. Never use `pacman -Syu` on Omarchy.
- Keep generated/runtime state out of source files. In particular, do not
  copy Herdr's machine-path-bearing plugin state into the repository.

## Verification

For a normal source change, run the narrowest applicable checks first:

```bash
chezmoi diff
just doctor
just check
```

For a template or install-script change, also render/check the affected
script. The pull-request workflow performs a non-mutating chezmoi render,
ShellCheck on rendered shell templates, and a repository secret scan.

Before reporting completion, inspect:

```bash
git diff --check
git status --short
git diff --stat
```

Do not claim a commit or push unless the command actually succeeded. The
operator decides when a reviewed change is committed or pushed.
