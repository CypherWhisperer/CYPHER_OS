# `src/pkgs/noeta/hermes_agent/`

**Module:** `cypher-os.pkgs.noeta.hermes.*`
**Context:** Home Manager (`hm.nix`) and NixOS (`system.nix`)
**Last updated:** 2026-10-13

---

## Purpose

- Configures [Hermes Agent](https://github.com/NousResearch/hermes-agent) (Nous Research), a model-agnostic, self-extending agent that keeps persistent memory and skills.
- Upstream's [Nix setup guide](https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup) documents the flake and its modules.

- Hermes is configured entirely under Home Manager.
- The NixOS side holds only user lingering, which Home Manager cannot enable.

---

## Layout

| File           | Responsibility                                                                                                                                               |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `options.nix`  | Declares `enable`, `gateway.enable` and `gui.enable` under `cypher-os.pkgs.noeta.hermes`                                                                     |
| `defaults.nix` | Defaults and assertions. Imported by both `hm.nix` and `system.nix`                                                                                          |
| `hm.nix`       | The whole Hermes configuration: CLI (`programs.hermes-agent`), optional desktop app, and the gateway as a `systemd --user` service (`services.hermes-agent`) |
| `system.nix`   | `users.users.<username>.linger = true`, gated on `enable && gateway.enable`                                                                                  |

Requirements outside this directory:

- The upstream flake input (`github:NousResearch/hermes-agent`) and `inputs.hermes-agent.homeManagerModules.default` in the Home Manager imports. Upstream's NixOS module is not used and not imported.
- The option set must be visible in both evaluation contexts. Home Manager and NixOS have separate option trees, so the toggles must be set in each, following the repository's existing dual-context convention.
- `cypherOsProfile` and `cypherOsConstants.username` as module arguments.

---

## Key Decisions Made

- **Home Manager first-class; system side is linger only.** See [ADR_030](../../../../../project/decisions/ADR_030_2026_10_13_run_hermes_agent_under_home_manager_with_linger_only_system_side.md).
- **Model default and credentials stay imperative.** See [ADR_031](../../../../../project/decisions/ADR_031_2026_10_13_keep_hermes_runtime_state_imperative.md).
- **No duplicated service declaration across contexts, and no dedicated service user.** The agent runs as the user under `systemd --user`.

---

## Key Reminders, Warnings and Notes

- **Linger is required for the gateway:**
    - Without it, `systemd` stops the user manager at logout and the gateway stops with it; upstream's checks also treat cron dispatch as failing closed.
    - On NixOS, `system.nix` handles this. On other systems, enable it once by hand: `loginctl enable-linger <user>`.
- **Nix-owned keys:**
    - Any key declared under `services.hermes-agent.settings` is merged into `config.yaml` on every rebuild and becomes read-only to the Hermes CLI (the `.managed` marker).
    - Undeclared keys remain freely editable. The model default is deliberately not declared; `hm.nix` carries a comment block explaining the exclusion and its possible future use.
- **Possible future use of a declared model:**
    - Declare `settings.model.default` (ideally through a shared constant) only where a Nix-enforced baseline must resist drift: a CI host, a shared account, or a machine where a fixed model is non-negotiable.
- **Credentials:**
    - `~/.hermes/.env` is rewritten only when `environment` or `environmentFiles` is non-empty; with neither set, it is managed imperatively through Hermes.
    - Never put secrets in `environment` or reference them as Nix path literals: both copy them into the world-readable Nix store.
    - When a secrets manager is adopted, pass a runtime path string through `environmentFiles`. `authFile` (installed as `auth.json`, not overwritten if present) exists for providers with a login flow and is not used yet.
- **Blast radius:**
    - The agent executes shell commands and reaches external services with the user's own permissions; there is no service-account isolation.
- **Desktop application:**
    - `gui.enable` maps to `programs.hermes-agent.desktop.enable`. No official Linux desktop release was found (see the [desktop README](https://github.com/nousresearch/hermes-agent/blob/main/apps/desktop/README.md) and [issue 104469](https://github.com/NousResearch/hermes-agent/issues/104469)), so the package may be unavailable on a given host.
    - Leave `gui.enable` off if the build fails.
- **Option names come from upstream's source:**
    - If a rebuild reports a nonexistent option, read upstream's `nix/homeManagerModules.nix` and `nix/moduleCommon.nix`, or let `home-manager build` report it.

---

## Verification

```bash
home-manager build                              # evaluates hm.nix against upstream's module
loginctl show-user "$USER" -p Linger            # Linger=yes after a NixOS rebuild with the gateway enabled
systemctl --user status                         # then check the Hermes gateway unit
hermes --help
```

---

## Related

- Journal: [2026_10_13_agentic_tooling_stack_setup](../../../../../development/journal/2026_10_13_agentic_tooling_stack_setup.md)
- Sibling module: [dsh](../dsh.md)