# Dotfiles

Chezmoi-managed dotfiles for the operator's macOS and Omarchy/Linux machines.
The repository keeps platform differences, package ownership, encrypted
configuration, and machine-local values explicit instead of copying one
machine's home directory wholesale.

## Quick start

Install chezmoi and initialize this repository on a new machine:

```bash
chezmoi init --apply https://github.com/happyhaha1/dotfiles.git
```

During an interactive initialization, choose the machine profile and whether
the machine has the shared age/SSH key. The age identity is expected at:

```text
~/.ssh/main
```

On an existing machine, inspect first and apply deliberately:

```bash
chezmoi update
chezmoi diff
chezmoi apply
```

Run the local health checks with:

```bash
just doctor
just check
```

## Machine profiles

The persistent chezmoi data selects the profile used by templates and install
scripts:

- `daily` — the normal interactive Mac profile.
- `home-server` — a macOS server profile with reduced desktop setup.
- `office-server` — the office/server profile; this is also where the Collie
  LAN integration is currently enabled.
- `other` — safe fallback for non-interactive or unclassified machines.

Private machine values such as Collie's LAN host are stored in the local
chezmoi config (`chezmoi edit-config`), never in `.chezmoidata/` or a normal
tracked template.

## Package ownership

Use the manager that owns the kind of dependency:

| Manager | Responsibility | Source |
| --- | --- | --- |
| Homebrew | macOS formulas, casks, fonts, and App Store apps | `.chezmoidata/homebrew.yaml` |
| Aqua | pinned portable CLI binaries | `private_dot_config/aquaproj-aqua/aqua.yaml` |
| mise | language runtimes and selected runtime tools | `private_dot_config/mise/config.toml.tmpl` |
| Fisher | Fish plugins | `private_dot_config/private_fish/fish_plugins.tmpl` |
| chezmoi scripts | platform setup, services, and package orchestration | `.chezmoiscripts/` |

Do not install a tool manually when it already has a declaration in one of
these sources; update the declaration and apply it instead.

## Herdr and Collie

Herdr itself is pinned in Aqua. Herdr plugins are declared in
`.chezmoidata/herdr.yaml` and synchronized by the numbered Herdr script. The
scheduled version workflow updates stable plugin refs and opens a PR; it does
not install anything on a machine automatically.

Collie is currently configured for direct LAN access on the office-server
profile. Its host value is machine-local, while the tracked template only
references `{{ .collieHost }}`. Review the generated `.env` with `chezmoi
diff` before starting or restarting the service.

## Encryption and private data

Age-encrypted files are intentionally unreadable without the configured key.
Do not replace encrypted files with plaintext to make a check pass, and do not
commit API keys, IP addresses that should remain private, or generated service
state. See `docs/migrate-from-nix.md` for migration context; recovery guidance
will be maintained separately from the applied dotfiles.

## Automation

- `.github/workflows/update-versions.yml` updates pinned versions and creates
  a dependency PR.
- `.github/workflows/update-aqua-packages.yml` updates Aqua's registry and
  package pins.
- `.github/workflows/scheduler.yml` triggers the scheduled update workflows.
- `.github/workflows/ci.yml` validates templates, rendered shell scripts, and
  repository secrets on pull requests and pushes to `main`.

## Safety

This is a declarative configuration repository, not an unattended deployment
pipeline. Review `chezmoi diff` before applying changes, and obtain explicit
operator approval before committing or pushing changes.
