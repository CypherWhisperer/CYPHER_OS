# ADR_010_2026_06_16: `programs.*` Module Ownership Required for catppuccin/nix Theming

**Date:** 2026-06-16  
**Status:** Accepted  
**Deciders:** CypherWhisperer

---

## Context

CypherOS uses `catppuccin/nix` with `catppuccin.autoEnable = true` as the primary mechanism for applying Catppuccin Mocha Mauve theming across supported applications. During the June 2026 theming pass, OBS Studio and Zathura both failed to receive Catppuccin theming despite `catppuccin.autoEnable = true` being set globally.

Investigation revealed the root cause: both applications were installed via `environment.systemPackages` rather than through Home Manager's `programs.*` module system. The `catppuccin/nix` Home Manager modules work by extending `programs.<app>` option sets — writing theme configuration files, setting active theme names, or injecting colour definitions into the application's HM-managed config. When an application is installed at the NixOS system level via `environment.systemPackages`, no corresponding `programs.<app>` module is activated in Home Manager, and the catppuccin hook has nothing to attach to.

This is not a bug in catppuccin/nix — it is a fundamental consequence of how HM module composition works. It has broad implications: any application added to CypherOS via `environment.systemPackages` will silently receive no catppuccin theming, with no evaluation error or warning to indicate the gap.

---

## Decision

Any application that is supported by `catppuccin/nix` and requires Catppuccin theming **must** be declared via its Home Manager `programs.<app>` module. Installation via `environment.systemPackages` is disqualified for such applications. This is a standing architectural rule for CypherOS, not a per-application decision.

---

## Reasoning

`catppuccin/nix` Home Manager modules are implemented as extensions of `programs.<app>` option sets. The module for a given app activates only when `programs.<app>.enable = true` is set in the HM context. There is no mechanism by which catppuccin/nix can detect or theme an application installed at the system level — the two declaration planes are separate and do not share configuration state in the direction needed.

The failure mode is silent: `catppuccin.autoEnable = true` evaluates without error, the application runs, but it receives no theme. This is worse than a build failure because it produces invisible gaps in the theming stack that are only noticed visually. Establishing a firm rule eliminates the ambiguity at declaration time rather than at visual audit time.

The rule also aligns with the broader CypherOS principle of preferring HM user-space declarations over NixOS system-level declarations for user applications (established in ADR_005). `programs.*` ownership for catppuccin-managed apps is a natural extension of that principle.

---

## Alternatives Considered

### Case-by-case judgement — `environment.systemPackages` where convenient

Allow developers to choose between `environment.systemPackages` and `programs.<app>` on a per-app basis, relying on visual audits to catch theming gaps. Rejected because the failure mode is silent — there is no static analysis or evaluation warning that flags a misconfigured app. Case-by-case judgement produces inconsistent theming that is only discoverable at runtime.

### Manual theming for `environment.systemPackages` apps

Install via `environment.systemPackages` and manually write theme configuration via `home.file` or `xdg.configFile`, bypassing catppuccin/nix entirely. Rejected because it duplicates work that catppuccin/nix already performs correctly when the `programs.*` hook is active, and produces configuration that must be manually updated when catppuccin/nix changes its theming approach. The `programs.*` path is strictly less work with better long-term maintainability.

---

## Consequences

**Positive:**

- Catppuccin theming gaps are eliminated at declaration time — if an app supports catppuccin/nix and is declared via `programs.*`, it will be themed. No silent failures.
- Consistent with ADR_005's preference for HM user-space declarations.
- Reduces the surface area of manual `home.file`/`xdg.configFile` theming declarations — catppuccin/nix handles the implementation.

**Negative / Trade-offs:**

- Not all applications have a HM `programs.*` module. Applications without one cannot use catppuccin/nix and require manual `home.file` theming — this rule does not help them. Affected apps must be identified and handled case-by-case (e.g. LibreOffice, OhMyREPL).
- Some `programs.*` modules impose opinions (default config file paths, option namespaces) that may conflict with existing manual configuration. Migration from `environment.systemPackages` to `programs.*` requires auditing for conflicts.

**Neutral / Operational:**

- When adding a new application to CypherOS, the first check should be: does `catppuccin/nix` support it? If yes, declare it via `programs.<app>.enable = true` in the appropriate HM module. The catppuccin/nix supported application list is at `https://nix.catppuccin.com/options/`.
- Applications already in `environment.systemPackages` that have catppuccin/nix support should be migrated to `programs.*` as they are encountered. No bulk migration is required immediately — migrate on contact.
- This rule applies only to HM-context declarations. NixOS system services (daemons, system-wide tools) are not subject to this rule and remain in `environment.systemPackages` or `systemd.services` as appropriate.