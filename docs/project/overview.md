# Architecture Overview

**Version:** 0.2.0
**Status:** Active — post-refactor
**Author:** CypherWhisperer

---

## Vision Statement

A single physical machine where multiple operating systems co-exist as bootable _lenses_ into one unified system — sharing identity, data, software, and configuration. Booting a different OS is not starting over; it is changing perspective.

→ Full design intent: [`VISION.md`](../../VISION.md)

---

## Goals

|ID|Goal|
|---|---|
|G1|**Unified Identity** — One user (`cypher-whisperer`, UID `1000`) recognised natively by every OS on the machine.|
|G2|**Shared Home** — One home directory, one set of personal data, accessible regardless of which OS is booted.|
|G3|**DE Isolation Without User Splitting** — Hyprland, GNOME, and KDE Plasma co-exist for the same user without config conflicts, via XDG profile separation.|
|G4|**Single Software Source of Truth** — Nix + Home Manager manages all user-space software, DEs, and dotfiles. Native package managers handle only OS-critical internals.|
|G5|**Declarative & Reproducible** — The entire user environment is declared in a Nix flake. A fresh OS install + flake apply = full environment restored.|
|G6|**Extensible** — Adding a new OS, user, or DE is additive — not a redesign.|
|G7|**LFS-Ready** — No design assumption requires a specific package manager or init system at the identity or data layer.|

---

## Non-Goals

- Network-attached storage / backup server — future phase
- Multi-machine sync — future phase
- Encrypted home image (systemd-homed style) — explicitly rejected; incompatible with the shared subvolume model
- Full FreeBSD feature parity — best-effort, not blocking

---

## System Architecture

The system is composed of five pillars, each owning a distinct layer of concerns. They are designed to be as independent as possible — a decision in P1 does not force a specific choice in P4.

```mermaid

flowchart TB
    subgraph P1["P1 — Filesystem & Partition Layer"]
        DISK["Single SSD<br>GPT: 2 partitions"]
        ESP["p1 — FAT32 EFI<br>512MB / 1GB<br>shared ESP"]
        BTRFS["p2 — BTRFS<br>remainder"]
        DISK --> ESP
        DISK --> BTRFS
    end

    subgraph SUBVOLS["BTRFS Subvolumes"]
        ROOTS["OS Roots<br>@arch-root<br>@debian-root<br>@fedora-root<br>@nixos-root"]
        SHARED["Shared Subvolumes<br>@home → /home<br>@nix-store → /nix<br>@identity → /var/lib/extrausers"]
        DBMS["NixOS Service Data<br>@dbms_postgres<br>@dbms_mariadb<br>@dbms_valkey<br>@dbms_meilisearch<br>@dbms_mongo<br>@dbms_neo4j<br>(NixOS-only, currently not cross-OS shared)"]
        UTIL["Utility<br>@snapshots<br>@swap"]
        BTRFS --> ROOTS
        BTRFS --> SHARED
        BTRFS --> UTIL
        BTRFS --> DBMS
    end

    subgraph P2["P2 — Identity Layer"]
        EXTRAUSERS["libnss-extrausers<br>(Arch, Debian, Fedora)"]
        NIXDECL["uid = 1000 declaration<br>(NixOS configuration.nix)"]
        VIPW["vipw<br>(FreeBSD)"]
        SHARED --> EXTRAUSERS
        SHARED --> NIXDECL
        SHARED --> VIPW
    end

    subgraph P3["P3 — Home & XDG Layer"]
        HOME["/home/cypher-whisperer<br>@home subvolume"]
        XDG["XDG Profile Separation<br>.config/profiles/gnome<br>.config/profiles/plasma<br>.config/profiles/hyprland"]
        HOME --> XDG
    end

    subgraph P4["P4 — Software Layer"]
        NIX["Nix Daemon<br>multi-user"]
        HM["Home Manager<br>DEs, apps, dotfiles, fonts"]
        NIXOS["NixOS<br>full system config"]
        NIX --> HM
        NIX --> NIXOS
        DBMS --> NIXOS
    end

    subgraph P5["P5 — Declarative Layer"]
        FLAKE["CypherOS flake.nix<br>single source of truth"]
        LOCK["flake.lock<br>reproducibility pin"]
        FLAKE --> LOCK
    end

    SHARED --> HOME
    SHARED --> NIX
    P5 --> P4
```

---

## Pillar 1 — Filesystem & Partition Layer

**Technology:** BTRFS on a single SSD, structured with subvolumes.

The partition table is deliberately minimal — exactly two partitions. All structural complexity lives inside the BTRFS layer as subvolumes, not as partitions. This is the key property that makes adding a new OS additive rather than disruptive: a new OS is a new subvolume, not a repartition.

```mermaid

block-beta
    columns 3

    block:disk:3
        label["Single SSD"]
    end

    block:p1:1
        efi["p1 — FAT32<br>EFI System Partition<br>512MB–1GB<br>shared by all OSs<br>systemd-boot"]
    end

    block:p2:2
        btrfs["p2 — BTRFS<br>All subvolumes<br>No pre-defined sizes<br>Shared pool"]
    end
```

**Subvolume layout:**

```mermaid

flowchart LR
    BTRFS["BTRFS<br>p2"]

    BTRFS --> arch["@arch-root<br>→ / (Arch)"]
    BTRFS --> debian["@debian-root<br>→ / (Debian)"]
    BTRFS --> fedora["@fedora-root<br>→ / (Fedora)"]
    BTRFS --> nixos["@nixos-root<br>→ / (NixOS)"]

    BTRFS --> home["@home<br>→ /home<br>SHARED — all Linux OSs"]
    BTRFS --> nix["@nix-store<br>→ /nix<br>SHARED — CoW disabled"]
    BTRFS --> identity["@identity<br>→ /var/lib/extrausers<br>SHARED — read-only"]

    BTRFS --> snap["@snapshots<br>→ /.snapshots"]
    BTRFS --> swap["@swap<br>→ /swap<br>CoW disabled"]
    
    BTRFS --> dbms_pg["@dbms_postgres<br>→ /dbms/postgres<br>Currently NixOS-only"]
    BTRFS --> dbms_maria["@dbms_mariadb<br>→ /dbms/mariadb<br>Currently NixOS-only"]
    BTRFS --> dbms_valkey["@dbms_valkey<br>→ /dbms/valkey<br>Currently NixOS-only"]
    BTRFS --> dbms_meili["@dbms_meilisearch<br>→ /dbms/meilisearch<br>Currently NixOS-only, dormant"]
    BTRFS --> dbms_mongo["@dbms_mongo<br>→ /dbms/mongo<br>Currently NixOS-only, dormant"]
    BTRFS --> dbms_neo4j["@dbms_neo4j<br>→ /dbms/neo4j<br>Currently NixOS-only, dormant"]
```

**Key constraints:**

- `@nix-store` — CoW disabled via `chattr +C` before first Nix write. BTRFS CoW and Nix hardlinks interact poorly without this.
- `@swap` — CoW disabled via `chattr +C`. A hard BTRFS requirement for swapfiles. The kernel refuses to activate swap on a CoW-enabled file.
- `@freebsd-root` — FreeBSD cannot natively mount BTRFS. Separate UFS/ZFS partition or best-effort compatibility layer. Resolved in Phase 10.
- Subvolumes share the BTRFS pool freely. No pre-defined sizes. No repartitioning to add an OS.
  
- `@dbms_*` subvolumes — always mounted as **top-level siblings** of `@nixos-root`/`@home`/`@nix-store`/`@swap`, never nested inside another mounted subvolume. Nesting caused a real incident (see [INC_2026_04_10_001](../development/incidents/INC_2026_04_10_001_@data_subvolume_silently_unmounted_after_rebuild_(nested_subvolume_mount_ordering).md) — `@data` subvolume incident and [ADR_017](decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md)): systemd does not reliably guarantee mount ordering for a subvolume mounted inside an already-mounted one.

**Swap strategy:**

```mermaid
flowchart TD
    RAM["RAM (free)"]
    ZRAM["/dev/zram0<br>ZRAM — compressed RAM<br>fast, high priority<br>per-OS, kernel-level"]
    SWAPFILE["/swap/swapfile<br>@swap subvolume<br>disk-backed, slow<br>last resort"]

    RAM -->|"memory pressure"| ZRAM
    ZRAM -->|"ZRAM full"| SWAPFILE
```

---

## Pillar 2 — Identity Layer

**Technology:** `libnss-extrausers` on Linux; explicit `uid = 1000` on NixOS; `vipw` on FreeBSD.

The load-bearing piece of the identity layer is UID consistency. File ownership on shared BTRFS subvolumes resolves by UID number, not by username string. Every OS must agree on `cypher-whisperer = UID 1000`.

```mermaid
flowchart TB
    IDENT["@identity subvolume<br>/identity/passwd<br>/identity/shadow<br>/identity/group"]

    IDENT -->|"bind-mount → /var/lib/extrausers<br>nsswitch: extrausers after files"| ARCH["Arch Linux<br>libnss-extrausers"]
    IDENT -->|"bind-mount → /var/lib/extrausers<br>nsswitch: extrausers after files"| DEBIAN["Debian<br>libnss-extrausers"]
    IDENT -->|"bind-mount → /var/lib/extrausers<br>nsswitch: extrausers after files"| FEDORA["Fedora<br>libnss-extrausers"]
    IDENT -->|"uid = 1000 declared<br>in configuration.nix"| NIXOS["NixOS<br>native declaration"]
    IDENT -->|"manual vipw entry<br>UID must match"| FREEBSD["FreeBSD<br>vipw"]
```

**Canonical identity record:**

```
# @identity/passwd
cypher-whisperer:x:1000:1000:Cypher Whisperer:/home/cypher-whisperer:/bin/zsh

# @identity/group
cypher-whisperer:x:1000:
wheel:x:998:cypher-whisperer
video:x:986:cypher-whisperer
audio:x:985:cypher-whisperer
```

**`systemd-homed` is explicitly out of scope.** It manages identity per-OS locally and enters an `unfixated` state when a user record exists on one OS but not another. It was never designed as a shared identity store. See [`docs/project/tech-stack.md`](https://claude.ai/chat/tech-stack.md) for the full reasoning.

---

## Pillar 3 — Home & XDG Profile Layer

**Technology:** Shared `@home` BTRFS subvolume + XDG environment variable overrides per DE session.

One home directory — `/home/cypher-whisperer` on `@home` — mounted by every Linux OS. All personal data (documents, projects, SSH keys, GPG keys) lives here and is always accessible regardless of which OS is booted.

**The DE conflict problem:** Running Hyprland and GNOME under the same `$HOME` without isolation causes fights over:

- `~/.config/mimeapps.list` — both DEs overwrite default app associations
- `~/.config/autostart/` — GNOME autostart entries fire in Hyprland sessions
- `~/.local/share/` — state files collide (recently-used, bookmarks)
- D-Bus session services — GNOME services (`gvfs`, `tracker`) do not coexist cleanly with non-Mutter compositors

**The solution — XDG Profile Separation:**

Each DE is launched via a Home Manager-managed wrapper script that overrides XDG base directories before exec-ing the session:

```bash
# ~/.local/bin/launch-gnome
export XDG_CONFIG_HOME="$HOME/.config/profiles/gnome"
export XDG_DATA_HOME="$HOME/.local/share/profiles/gnome"
export XDG_CACHE_HOME="$HOME/.cache/profiles/gnome"
export XDG_STATE_HOME="$HOME/.local/state/profiles/gnome"
exec gnome-session
```

Each launcher script is registered as a `.desktop` session entry with the display manager. The user selects the session at login — the DM shows each variant as a distinct choice.

```mermaid
flowchart TD
    HOME["/home/cypher-whisperer<br>@home subvolume"]

    HOME --> SHARED["Shared — not profiled<br>~/.ssh/<br>~/.gnupg/<br>~/.gitconfig<br>shell rc files<br>fonts"]

    HOME --> PROFILES[".config/profiles/"]
    PROFILES --> GNOME[".config/profiles/gnome/<br>.local/share/profiles/gnome/<br>.cache/profiles/gnome/"]
    PROFILES --> PLASMA[".config/profiles/plasma/<br>.local/share/profiles/plasma/<br>.cache/profiles/plasma/"]
    PROFILES --> HYPR[".config/profiles/hyprland/<br>.local/share/profiles/hyprland/<br>.cache/profiles/hyprland/"]
```

Intentionally not profiled *(shared across all DE sessions):* SSH keys, GPG keys, git config, shell rc files, fonts. Anything that does not cause DE conflicts stays generalized.

---

## Pillar 4 — Software Layer

**Technology:** Nix multi-user daemon + Home Manager on all OSs. NixOS gets full system Nix.

The boundary is clean: Nix owns everything _above_ the OS ABI. The native package manager owns everything _below_ it.

```mermaid
flowchart TB
    subgraph NIX_OWNS["Nix / Home Manager"]
        DE["DEs — Hyprland, GNOME, KDE Plasma"]
        APPS["All user-space applications"]
        SHELL["Shell + CLI tooling"]
        DOTS["Dotfiles + DE config"]
        FONTS["Fonts"]
        XDG["XDG launcher scripts"]
        DEVTOOLS["Dev tools, LSPs, runtimes"]
    end

    subgraph NATIVE_OWNS["Native Package Manager"]
        KERNEL["Kernel + kernel modules"]
        BOOT["Bootloader"]
        DRIVERS["Display drivers"]
        INIT["Init system"]
        DAEMONS["OS-level daemons"]
        LIBNSS["libnss-extrausers itself"]
    end

    subgraph NIXOS_EXCEPTION["NixOS (exception)"]
        NIXOS_ALL["Nix owns both columns<br>Full system declaration"]
    end
```

**Shared `@nix-store`:** Mounted at `/nix` by every OS that uses Nix. A package built once is available everywhere. Adding a second OS does not re-download or re-build anything already present in the store. `chattr +C` on the subvolume before the first Nix write is mandatory.

---

## Pillar 5 — Declarative & Dotfiles Layer

**Technology:** Nix Flakes + Home Manager modules in a git repository.

The `CypherOS` repository is the single source of truth. A fresh OS install plus `nixos-install --flake .#cypher-nixos` (or `home-manager switch --flake .#cypher-whisperer@arch`) reconstructs the full environment.

**`flake.nix` structure:**

```mermaid

flowchart TD
    FLAKE["flake.nix<br>Entry point"]

    FLAKE --> NIXOS_HOST["nixosConfigurations<br>cypher-nixos<br>hosts/nixos/configuration.nix"]
    FLAKE --> HM_CONFIGS["homeConfigurations<br>cypher-whisperer@arch<br>cypher-whisperer@debian<br>cypher-whisperer@fedora"]

    NIXOS_HOST --> HM_MODULE["home-manager.users.cypher-whisperer<br>→ modules/home/default.nix"]
    NIXOS_HOST --> SYSTEM_MODULES["system modules<br>→ modules/de/gnome/system.nix<br>→ modules/dm/gdm/system.nix<br>→ modules/devops/system.nix<br>→ ..."]

    HM_MODULE --> HM_ROOT["modules/home/default.nix<br>HM root — imports all modules<br>home.stateVersion"]
```

---

## Module Architecture — The `cypher-os` Namespace

All configuration options live under the `cypher-os` attribute tree. Every option you declare is a question CypherOS asks the host config: _"do you want this?"_

```mermaid

flowchart LR
    ROOT["cypher-os"]

    ROOT --> PROFILE["profile<br>├── desktop.enable<br>└── server.enable"]
    ROOT --> SHELL["shell<br>├── enable<br>├── zsh.enable<br>├── fish.enable<br>└── nushell.enable"]
    ROOT --> FONTS["extra-fonts.enable"]
    ROOT --> XDG["xdg-config.enable"]
    ROOT --> DE["de<br>├── gnome<br>│   ├── enable<br>│   └── variant<br>├── plasma<br>│   ├── enable<br>│   └── variant<br>└── hyprland<br>    ├── enable<br>    └── variant"]
    ROOT --> DM["dm<br>├── gdm.enable<br>└── sddm.enable"]
    ROOT --> APPS["apps<br>├── enable (kill switch)<br>├── browser<br>├── terminal<br>├── editor<br>├── productivity<br>├── dev<br>└── cli"]
    ROOT --> GAMING["gaming<br>├── enable<br>├── steam.enable<br>└── minecraft.enable"]
    ROOT --> DEVOPS["devops<br>├── enable<br>├── containers.enable<br>├── kubernetes.enable<br>├── databases.enable<br>├── iac<br>└── secrets"]
    ROOT --> VIRT["virtualisation<br>└── helpers.enable"]
```

**Profile cascade:**

One line in `configuration.nix` activates the entire desktop stack:

```nix
cypher-os.profile.desktop.enable = true;
```

This cascades via `lib.mkDefault` through the module system:

```mermaid
flowchart TD
    DESKTOP["cypher-os.profile.desktop.enable = true"]
    DESKTOP -->|"mkDefault true"| GNOME_EN["cypher-os.de.gnome.enable"]
    DESKTOP -->|"mkDefault true"| GDM_EN["cypher-os.dm.gdm.enable"]
    DESKTOP -->|"mkDefault true"| APPS_EN["cypher-os.apps.enable"]

    GNOME_EN --> GNOME_MOD["gnome/system.nix<br>services.desktopManager.gnome.enable"]
    GDM_EN --> GDM_MOD["gdm/system.nix<br>services.displayManager.gdm.enable"]
    APPS_EN --> APP_MODS["apps/**/hm.nix<br>home.packages, programs.*"]

    OVERRIDE["host override:<br>cypher-os.dm.gdm.enable = false<br>cypher-os.dm.sddm.enable = true"]
    OVERRIDE -->|"explicit assignment beats mkDefault"| GDM_EN
```

For the full module architecture specification, see [ADR-005 — Module Architecture](https://claude.ai/project/decisions/ADR-005-module-architecture.md).

---

## Integration Map

How the five pillars connect at runtime when booted into any Linux OS on the machine:

```mermaid

flowchart TB
    subgraph DISK["Physical Disk — BTRFS"]
        subgraph OS_ROOTS["OS Root Subvolumes"]
            ARCH["@arch-root"]
            DEBIAN["@debian-root"]
            FEDORA["@fedora-root"]
            NIXOS["@nixos-root"]
        end
        subgraph SHARED_VOLS["Shared Subvolumes"]
            HOME_VOL["@home<br>→ /home"]
            NIX_VOL["@nix-store<br>→ /nix"]
            ID_VOL["@identity<br>→ /var/lib/extrausers"]
        end
    end

    OS_ROOTS -->|"fstab mounts"| SHARED_VOLS

    ID_VOL -->|"nsswitch extrausers"| IDENTITY["Identity<br>cypher-whisperer UID 1000<br>recognised on every OS"]
    NIX_VOL -->|"Nix daemon<br>multi-user"| SOFTWARE["Software Layer<br>Nix + Home Manager<br>DEs, apps, dotfiles"]
    HOME_VOL -->|"XDG profile<br>launcher scripts"| HOME_LAYER["Home & XDG<br>one home directory<br>per-DE config namespace"]

    SOFTWARE -->|"flake apply"| FLAKE_SRC["CypherOS<br>flake.nix<br>git repo"]
```

---

## Implementation Sequence

→ See [`ROADMAP.md`](https://claude.ai/ROADMAP.md) for the full phase breakdown with status tracking.

---

## Open Questions & Known Trade-offs

| #   | Question                                                                                                                                         | Status                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| OQ1 | Nix daemon mode — single-user vs multi-user on non-NixOS                                                                                         | ✅ Decided: multi-user on all OSs                                             |
| OQ2 | FreeBSD `@home` access — BTRFS incompatible                                                                                                      | ⊙ Phase 10 — likely exFAT/ext4 shared partition                              |
| OQ3 | FreeBSD password hash format — yescrypt vs SHA-512                                                                                               | ⊙ Phase 10 — sync script needed                                              |
| OQ4 | GNOME Keyring / KWallet isolation under XDG profiling                                                                                            | ⊙ Verify Phase 7                                                             |
| OQ5 | BTRFS CoW + Nix hardlinks                                                                                                                        | ✅ `chattr +C` on `@nix-store` before Nix install                             |
| OQ6 | Shared ESP + systemd-boot vs per-OS EFI                                                                                                          | ⊙ Decided Phase 0 — shared ESP + systemd-boot                                |
| OQ7 | Should `@dbms_*` subvolumes become cross-OS shared *(like `@home`)* via fstab entries on Arch/Debian/Fedora too, or stay NixOS-only permanently? | ⚠️ Undecided — *currently NixOS-only by default, not a deliberate exclusion* |
