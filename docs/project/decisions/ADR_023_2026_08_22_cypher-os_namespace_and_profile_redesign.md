# ADR_023_2026_08_22: `cypher-os` Namespace and Profile Redesign

**Date:** 2026-08-22
**Status:** Accepted
**Deciders:** CypherWhisperer
**Supersedes:** [ADR-001 — `cypher-os` Namespace Design](ADR_001_cypher-os_namespace_design.md)
**Related:**
1. [ADR-005 — Module Architecture](ADR_005_module_architecture.md) (amended alongside this ADR)
2. [ADR_024](ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md)
3. [ADR-013 — `flake.nix` Modularization](ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md)
4. [ADR-014 — Username String Change](ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md)

---

## Context

[ADR-001](../../project/decisions/ADR-001-cypher-os-namespace-design) established the original `cypher-os` namespace and a `profile` meta-switch built on two independent booleans (`profile.desktop.enable`, `profile.server.enable`). 

That design served the system through its early growth, but a dedicated design session (this session) surfaced several problems it can no longer absorb cleanly:

- **The profile mechanism admits invalid states.** Nothing in the dual-boolean design prevents both `desktop` and `server` being `true`, or both being `false`, at the same time — *there is no single value that unambiguously answers "what profile is this host."*
  
- **`apps.common.security` conflated two different concerns** — security _tooling_ *(nmap, wireshark, gobuster)* and privacy software *(Proton ecosystem, VPN, encrypted mail)* were sitting in one category with one `enable` switch, despite being different in kind and likely to grow in different directions.
  
- **`de`, `dm`, `shell`, `extra-fonts`, `xdg-config`** were treated as flat, same-level leaves under `cypher-os`, with no room to express that some of these categories *(fonts, in particular)* need genuinely different config depending on whether Home Manager is running under a NixOS host or a foreign-distro lens *(Arch, Debian, Fedora, openSUSE)* — a distinction the namespace had no way to express at all.
  
- **No namespace home existed for cross-cutting state:**
    - the system now needs to reason about:
        - build-time constants *(username, home directory, primary disk, vault paths)* and which "lens" *(NixOS vs. a foreign distro)* a given host is running under.
  
- The repo tree underwent a parallel redesign in the same session *(see the companion tree/changes document),* settling on a `pkgs/` vs. `system/` split at the top level of the repository. Per prior convention, the namespace is designed to mirror the repo tree 1:1 rather than diverge from it.

## Decision

The `cypher-os` namespace is restructured as follows:

1. **`cypher-os.profile.active`** replaces the two independent booleans. It is a single enum, `"desktop" | "server"` — *exactly one value is ever true.*
   
2. **`cypher-os.lens.current`** is introduced as a new, parallel SSOT signal:
    - an enum, `"nixos" | "arch" | "debian" | "fedora" | "opensuse"`, naming which host lens is active.
    - See ADR-024 for how both signals propagate across evaluation contexts.
   
3. **The namespace nests under `cypher-os.pkgs.*` and `cypher-os.system.*`**, 
    - mirroring the repo tree's top-level `pkgs/`/`system/` split exactly. 
    - Categories that don't cleanly belong to either branches (e.g, `de`, `dm`, `shell`, `fonts`, `xdg`) sit as their own top-level siblings — `cypher-os.de.*`, `cypher-os.dm.*`, `cypher-os.shell.*`, `cypher-os.fonts.*`, `cypher-os.xdg.*` — *rather than being forced into one bucket or the other.*
   
4. **`apps.common.security` is split** into two sibling top-level categories:
    - `cypher-os.security.*` *(tooling: nmap, tor, tcpdump, strace, gobuster, wireshark, keepassxc)*
    - and `cypher-os.privacy.*` *(Proton ecosystem, MegaSync, and future privacy-first software).*
   
5. **`apps.cli` is split** into:
    1. `cypher-os.pkgs.core.*` *(the ungated, always-installed CLI toolbelt — `fzf, ripgrep, bat, fd, tree, ranger, curl, wget, rsync, keychain, lf, yazi`)*
    2. and `cypher-os.pkgs.cli.*` *(individually-toggleable TUI applications that already warrant their own leaf module — `btop, htop, tmux, zellij, fastfetch`).*
   
6. **`cypher-os.pkgs.utils.*`** is introduced to hold general-purpose utility software *(disk-utils and similar)* that isn't part of the core toolbelt.
   
7. **`cypher-os.constants.*`** is introduced as a new top-level category — *see the constants section of the full tree below.*
   
8. **`arduino`** is placed under `cypher-os.pkgs.dev.arduino.*`; **`virtualisation`** is placed under `cypher-os.system.virtualisation.*` — both were present in the codebase but absent from [ADR_001](ADR_001_cypher-os_namespace_design.md)'s documented tree.

## Reasoning

**Enum over dual boolean:**
- an enum makes the invalid states (both-true, both-false) unrepresentable rather than merely discouraged-by-convention.
- It also gives `osConfig`-based propagation (ADR-024) a single value to read, rather than two values that could in principle disagree with each other across evaluation contexts.

**Nested `pkgs`/`system`, with named exceptions:**
- mirroring the repo tree exactly keeps "where does this option live" and "where does this option's implementation live" answerable with the same mental model, which was ADR-001's own stated goal (decisions over files) — the repo tree itself changed, so the namespace mirroring it must change too.
- The exceptions *(`de`, `dm`, `shell`, `fonts`, `xdg`)* are not a violation of that mirroring principle; the repo tree itself gives these categories their own top-level directories rather than filing them under `pkgs/` or `system/`, because each genuinely spans both evaluation contexts rather than belonging cleanly to one.

**Security/privacy split:**
- These are different domains that happen to have been filed together by convenience, not by design — recon/audit tooling and daily-driver privacy software have different growth trajectories and different reasons to be enabled independently of one another.

**Core/CLI split:**
- `apps.cli`'s original file mixed an always-on flat package list with individually-toggleable TUI programs in the same `config` block, which meant the un-gated tools had no clear category identity of their own and the gated ones had no clear separation from them.
- Splitting makes each category's contents legible from its name alone.

## Full Namespace Tree

```
cypher-os
├── profile
│   └── active                      # enum: "desktop" | "server"
│
├── lens
│   └── current                     # enum: "nixos" | "arch" | "debian" | "fedora" | "opensuse"
│
├── constants
│   ├── username
│   ├── homeDirectory                # independent of username — see ADR-014
│   ├── primaryDisk
│   └── vaultPath
│
├── de
│   ├── gnome.{enable,variant}
│   ├── plasma.{enable,variant}
│   └── hyprland.{enable,variant}
│
├── dm
│   ├── gdm.enable
│   └── sddm.enable
│
├── shell
│   ├── enable
│   ├── zsh.enable
│   ├── fish.enable
│   └── nushell.enable
│
├── fonts.enable                     # implication depends on lens.current — see ADR-024
├── xdg.enable
│
├── security
│   ├── enable
│   ├── wireshark.enable             # GUI, profile-conditional
│   └── keepassxc.enable             # GUI, profile-conditional
│
├── privacy
│   ├── enable
│   ├── protonVpn.enable
│   ├── protonPass.enable
│   ├── protonMail.enable
│   └── megasync.enable
│
├── pkgs
│   ├── core.enable                  # ungated baseline toolbelt
│   ├── cli
│   │   ├── enable
│   │   ├── btop.enable
│   │   ├── htop.enable
│   │   ├── tmux.enable
│   │   ├── zellij.enable
│   │   └── fastfetch.enable
│   ├── utils
│   │   ├── enable
│   │   └── diskUtils.enable
│   ├── dev
│   │   ├── enable
│   │   ├── ssh.enable
│   │   ├── git.enable
│   │   ├── devenv.enable
│   │   ├── languages.{enable,go.enable,php.enable}
│   │   └── arduino.{enable,ide.enable,ota.enable}
│   ├── devops
│   │   ├── enable
│   │   ├── containers.enable
│   │   ├── kubernetes.enable
│   │   ├── dbmss.enable
│   │   ├── iac.{enable,terraform.enable}
│   │   ├── secrets.{enable,vault.enable}
│   │   ├── cicd.enable
│   │   ├── cloud.enable
│   │   └── observability.enable
│   ├── browser
│   │   ├── enable
│   │   ├── brave.enable
│   │   ├── firefox.enable
│   │   ├── librewolf.enable
│   │   ├── mullvad.enable
│   │   └── tor.enable
│   ├── editor
│   │   ├── enable
│   │   ├── vim.enable
│   │   ├── neovim.enable
│   │   ├── vscode.enable
│   │   └── zettlr.enable
│   ├── terminal.{enable,ghostty.enable,kitty.enable}
│   ├── mail.{enable,thunderbird.enable,protonBridge.enable}
│   ├── productivity
│   │   ├── enable
│   │   ├── obsidian.enable / penpot.enable / logseq.enable / affine.enable
│   │   └── zathura.enable / libreOffice.enable / obs.enable / d2.enable / anydesk.enable / rustdesk.enable
│   ├── gaming.{enable,steam.enable,minecraft.enable}
│   └── devshells.enable             # CLI/TUI-only devenv templates — see git_workflow.md
│
└── system
    ├── boot.enable
    ├── networking.enable
    ├── security.enable               # host-level hardening, distinct from cypher-os.security (tooling)
    ├── virtualisation.helpers.enable
    └── ... (further system-only categories as they are added)
```

## Alternatives Considered

### Keep the dual-boolean profile mechanism

**Rejected:**
- it permits invalid states *(both profiles true or false at once)* and gives ADR-024's `osConfig` propagation two values to keep in sync instead of one.
- An enum was the more direct fix once the propagation problem was being solved anyway.

### Flat namespace matching `nixpkgs`' own convention *(no `pkgs`/`system` nesting.)*

Considered seriously, since nixpkgs itself doesn't nest `services.*` under an artificial grouping.

**Rejected:**
- in favor of nesting because the repo tree already committed to a `pkgs/`/`system/` top-level split for organizational reasons independent of the namespace question, and 1:1 mirroring between namespace and repo tree was judged more valuable here than matching upstream convention, given this is a single-owner, single-tree system rather than a package set meant to compose with arbitrary others' configurations.

## Consequences

**Positive:**

- `profile.active` and `lens.current` are each a single source of truth, unblocking the cross-context propagation designed in ADR-024.
- Security and privacy tooling can each grow independently without crowding a shared category.
- The namespace and repo tree read as the same document in two forms — *finding an option tells you exactly where its implementation lives, and vice versa.*

**Negative / Trade-offs:**

- Every option path in every existing host config changes. This is a breaking, all-at-once migration, not an incremental one — tracked in the companion RFC's phased plan.
- `de`, `dm`, `shell`, `fonts`, `xdg` sitting outside both `pkgs` and `system` is a deliberate exception to the mirroring principle, and needs to be understood as such rather than mistaken for an oversight by a future reader.

**Neutral / Operational:**

- This ADR does not itself implement the migration — see [RFC_001](../rfcs/RFC_001_cypherOS_repo_and_namespace_restructure_implementation_plan.md) for the phased plan.