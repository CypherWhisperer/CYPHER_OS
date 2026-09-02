# ADR-001: `cypher-os` Namespace Design

**Date:** 2026-04-15
**Status:** Accepted
**Deciders:** CypherWhisperer

----
**Superseded By:** [ADR_023 CypherOS Namespace and profile redesign](ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md)

---

## Context

The CypherOS NixOS configuration had grown to a point where options were scattered and there was no coherent mental model for how to toggle features on and off. `gnome.nix` was doing too much, common modules were imported unconditionally, and the path to a server-profile version of the system (_no DE, no apps_) was unclear.

NixOS's module system provides a first-class mechanism for this: the **options system**. Rather than just setting values, you _declare typed options_ that modules then _implement_. The pattern is `[namespace].[group].[feature].enable = true|false`, using `lib.mkOption` + `lib.mkIf`. This is a foundational NixOS idiom. Understanding it unlocks everything else in the module architecture.

The question was: given this idiom, what should the CypherOS option tree look like? What are the right groupings, the right granularity, and the right cascading behavior?

---

## Decision

All CypherOS-specific configuration options are declared under a single `cypher-os` attribute namespace, organized into groups that reflect what you actually make decisions about — _not merely what exists in the codebase._

---

## Reasoning

The guiding principle was: **the namespace should reflect decisions, not files.** Every option you declare is a question CypherOS asks the host config: _"do you want this?"_ Before writing any Nix, think in terms of decisions.

The namespace tree and the file directory are deliberately decoupled. `cypher-os.apps.browsers.enable` can live in a file called `modules/apps/browser/default.nix` — _or `purple-elephant.nix`_. Nix does not care. Convention aligns them for sanity, but there is no technical coupling. This separation means the namespace can be designed around ergonomics and decision-making, not constrained by file layout.

**Profile meta-switches** are the top-level convenience layer. `cypher-os.profile.desktop.enable = true` activates the entire desktop stack (_DE + DM + apps_) via `lib.mkDefault` cascade. The host config can still override any individual piece. The implementation:

```nix
# In the profile module:
config = lib.mkIf config.cypher-os.profile.desktop.enable {
  cypher-os.de.gnome.enable = lib.mkDefault true;
  cypher-os.dm.gdm.enable   = lib.mkDefault true;
  cypher-os.apps.enable     = lib.mkDefault true;
};

# In configuration.nix — desktop on, but swap GDM for SDDM:
cypher-os.profile.desktop.enable = true;
cypher-os.dm.gdm.enable          = false;  # overrides the mkDefault
cypher-os.dm.sddm.enable         = true;
```

`lib.mkDefault` sets a priority lower than a normal assignment, so explicit host overrides always win. This is the "configure once, override precisely" pattern.

**`dm` coupling to `de`:** Display managers and DEs are technically independent but practically coupled — _GNOME strongly prefers GDM, Plasma prefers SDDM_. This is expressed as a default rather than a hard dependency:

```nix
# gnome module sets GDM as the default when gnome is enabled,
# but does not prevent overriding to SDDM:
config = lib.mkIf config.cypher-os.de.gnome.enable {
  cypher-os.dm.gdm.enable = lib.mkDefault true;
};
```

**`apps` granularity:** The namespace supports both coarse (`cypher-os.apps.browsers.enable` installs Brave + Firefox together) and fine-grained (`cypher-os.apps.browser.brave.enable`) toggles. The decision was to start coarse and add fine granularity progressively, only where toggling individual apps is actually needed.

---

## Full Namespace Tree

```
cypher-os
├── profile
│   ├── desktop.enable          # meta-switch: de + dm + apps
│   └── server.enable           # meta-switch: cli + dev + security (no DE)
│
├── shell
│   ├── enable
│   ├── zsh.enable
│   ├── fish.enable
│   └── nushell.enable
│
├── extra-fonts.enable
├── xdg-config.enable
│
├── devops
│   ├── enable
│   ├── containers.enable
│   ├── kubernetes.enable
│   ├── databases.enable
│   ├── iac.enable
│   ├── iac.terraform.enable
│   ├── secrets.enable
│   ├── cloud.enable
│   ├── cicd.enable
│   ├── networking.enable
│   ├── observability.enable
│   └── n8n.enable
│
├── virtualisation.helpers.enable
│
├── gaming
│   ├── enable
│   ├── minecraft.enable
│   └── steam.enable
│
├── de
│   ├── gnome
│   │   ├── enable
│   │   └── variant        # "vanilla" | "cypher" | ...
│   ├── plasma
│   │   ├── enable
│   │   └── variant        # "vanilla" | "macos" | ...
│   └── hyprland
│       ├── enable
│       └── variant        # "vanilla" | "hyde" | "celestia"
│
├── dm
│   ├── gdm.enable         # default true when gnome.enable
│   └── sddm.enable        # default true when plasma.enable
│
└── apps
    ├── enable             # master kill switch (default: true)
    ├── common
    │   ├── enable
    │   ├── disk-utils.enable
    │   ├── proton.enable
    │   └── security.enable
    ├── browser
    │   ├── enable
    │   ├── brave.enable
    │   └── firefox.enable
    ├── terminal
    │   ├── enable
    │   ├── kitty.enable
    │   └── ghostty.enable
    ├── editor
    │   ├── enable
    │   ├── vim.enable
    │   ├── neovim.enable
    │   └── vscode.enable
    ├── productivity
    │   ├── enable
    │   ├── claude.enable
    │   └── obsidian.enable
    ├── dev
    │   ├── enable
    │   ├── ssh.enable
    │   └── git.enable
    ├── mail
    │   ├── enable
    │   ├── thunderbird.enable
    │   └── protonBridge.enable
    └── cli
        ├── enable
        ├── tmux.enable
        ├── htop.enable
        ├── btop.enable
        └── fastfetch.enable
```

---

## Alternatives Considered

### Flat namespace (`cypher-os.gnome.enable`, `cypher-os.brave.enable`, ...)

A flat namespace is simpler to declare but harder to reason about at scale. There's no hierarchy to kill a whole group with one switch. `cypher-os.apps.enable = false` becomes `cypher-os.brave.enable = false; cypher-os.firefox.enable = false; cypher-os.kitty.enable = false; ...` — _verbose and error-prone_. The hierarchical namespace makes the kill-switch pattern work cleanly.

### Per-module namespaces (each module owns its own namespace root)

Having `gnome.enable`, `apps.enable`, etc. as top-level options (without the `cypher-os.` prefix) creates a risk of collisions with upstream NixOS options or other flake inputs. A single owned prefix namespaces everything cleanly and makes it immediately clear in any config file that an option is CypherOS-specific.

---

## Consequences

**Positive:**

- One line activates or deactivates entire feature categories.
- Host configs stay minimal and expressive — _the profile module handles the defaults, the host overrides precisely._
- New module groups plug in without touching existing configs.
- The namespace communicates intent — _reading `configuration.nix` tells you what the machine is, not just which files it imports._

**Negative / Trade-offs:**

- Every new module group requires declaring options in `options.nix` before implementing anything. This is a small upfront cost that pays forward as the system grows.
- Fine-grained toggles require more option declarations to maintain. The decision to start coarse mitigates this.

**Neutral / Operational:**

- The namespace and file paths are convention-aligned but technically independent. Deviating from the convention doesn't break anything — it just costs readability.
- `lib.mkDefault` in profile modules, explicit assignment in host configs — this distinction must be maintained consistently.
