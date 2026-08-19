# CypherOS

## NOTE: STILL UNDER DEVELOPMENT!

A unified multi-OS system on a single machine — _multiple operating systems sharing one identity, one home directory, one software layer, and one declarative configuration_. Booting a different OS is not starting over; it is changing perspective.

	This repository is the single source of truth for the entire system. It is a Nix Flake managed via [Home Manager](https://github.com/nix-community/home-manager), targeting NixOS as the canonical reference OS and extending to Arch, Debian, Fedora, and FreeBSD via the same user-space configuration.

→ For the full design rationale, see [`VISION.md`](https://claude.ai/chat/VISION.md).
→ For the technical architecture, see [`docs/project/overview.md`](https://claude.ai/chat/docs/project/overview.md).
→ For the technology stack breakdown, see [`docs/project/tech-stack.md`](https://claude.ai/chat/docs/project/tech-stack.md).

---

## Repository Structure

```
CypherOS/
├── flake.nix                          # Entry point
│                                      # defines all hosts an home configs
├── flake.lock                         # Pinned input revisions
├── hosts/
│   ├── nixos/
│   │   ├── configuration.nix           # Full CypherOS NixOS host
│   │   └── hardware-configuration.nix  # Machine-generated
│   ├── arch/
│   │   └── home.nix                    # Future: Arch Linux Home Manager config
│   ├── debian/
│   │   └── home.nix                    # Future: Debian Home Manager config
│   └── fedora/
│       └── home.nix                    # Future: Fedora Home Manager config
│
├── modules/
│   ├── default.nix
│   ├── options.nix
│   ├── fonts-hm.nix
│   ├── fonts-system.nix
│   ├── xdg-config.nix
│   ├── profile/
│   │   ├── default.nix           # Entry Point for profile/
│   │   │                         # Also exposes options to HM at evaluation
│   │   ├── system.nix            # System-concerned options.
│   │   │                         # Exposes options to NixOS at evaluation
│   │   └── options.nix           # Profile-Related options
│   │
│   ├── users/
│   │   ├── default.nix           # Entry Point for user/
│   │   └── cypher-whisperer.nix  # Canonical user declaration
│   │
│   ├── home/
│   │   └── default.nix           # Entry point for home/
│   │
│   ├── shell/
│   │    ├── default.nix
│   │    ├── options.nix
│   │    ├── system.nix
│   │    └── {zsh,fish,nushell}.nix
│   │
│   ├── de/
│   │   ├── default.nix        # Entry point for de/
│   │   ├── assets             # DE-related assets (wallpaper, avatar img, ...)
│   │   └── {gnome, hyprland,plasma}/
│   │       ├── default.nix    # DE Entry point
│   │       ├── options.nix    # DE-related options declaration.
│   │       ├── system.nix     # System concerns (install, sys-level configs)
│   │       ├── hm.nix         # Home Manager Concerns
│   │       └── {...}.nix      # Other DE related modules
│   │                          # Such as diff configuration variants
│   │
│   ├── apps/
│   │   ├── default.nix        # Entry point for apps/
│   │   ├── options.nix        # cypher-os.apps.enable option declaration
│   │   └── {browser,cli,common,dev,editor,productivity,terminal,mail}/
│   │       ├── default.nix    # Entry point for browser/
│   │       ├── options.nix    # Browsers-related options declaration.
│   │       ├── hm.nix         # Home Manager Concerns
│   │       └── {...}.nix      # app modules in each category.
│   │
│   ├── dm/
│   │   ├── default.nix        # Entry point for de/
│   │   ├── assets             # DM-related assets
│   │   └── {gdm, sddm}/
│   │       ├── default.nix    # dm Entry point
│   │       ├── options.nix    # dm-related options declaration.
│   │       ├── system.nix     # System concerns
│   │       └── {...}.nix
│   │
│   ├── {devops,virtualisation}/
│   │   ├── default.nix        # Entry point
│   │   ├── options.nix        # Related options declaration
│   │   ├── system.nix         # System Level Concerns
│   │   └── {...}.nix
│   │
│   └── gaming/
│       ├── default.nix        # Entry point for gaming/
│       ├── options.nix        # Gaming-Related options declaration
│       ├── minecraft.nix      # Minecraft Launcher and configuration
│       ├── steam-system.nix   # Steam System Level Concerns
│       └── steam-hm.nix       # Steam Home Manager Level Concerns
│
├── configs/                   # Configurations
├── scripts/                   # Scripts
└── identity/
    ├── passwd                 # Canonical extrausers passwd
    ├── group                  # Canonical extrausers group
    └── shadow                 # Gitignored — contains password hashes
```

---

## OS Fleet

| OS      | Status                                | Notes                                       |
| ------- | ------------------------------------- | ------------------------------------------- |
| NixOS   | **Active** — canonical reference OS   | Full system Nix, `configuration.nix` + HM   |
| Arch    | Planned                               | Phase 1 — base OS for BTRFS subvolume setup |
| Debian  | Originally running (_Trixie + GNOME_) | Source of the GNOME config replica          |
| Fedora  | Planned                               | Phase 9                                     |
| FreeBSD | Planned — _best-effort_               | Cannot mount BTRFS natively; Phase 10       |
| LFS     | Future                                | No pkg manager or init system assumptions   |

---

## Quick Reference — Common Commands

| Scenario                                                  | Command                                                                          |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Rebuild NixOS after config changes (_From the repo root_) | `sudo nixos-rebuild switch --install-bootloader --flake .#cypher-nixos --impure` |
| Rebuild — allow source builds on cache miss               | `sudo nixos-rebuild switch --flake .#cypher-nixos --option fallback true`        |
| Apply Home Manager only (_non-NixOS_)                     | `home-manager switch --flake .#cypher-whisperer@arch`                            |
| Check if a package has a cached binary                    | `nix path-info --store https://cache.nixos.org nixpkgs#<pkg>`                    |
| Roll back to previous generation                          | `sudo nixos-rebuild switch --rollback`                                           |
| Clean up old generations                                  | `sudo nix-collect-garbage -d && sudo nix store gc`                               |
| Update flake inputs                                       | `nix flake update`                                                               |
| Verify swap devices active                                | `swapon --show`                                                                  |
| Check memory and swap usage                               | `free -h`                                                                        |
| Debug keyd key events                                     | `sudo keyd monitor`                                                              |

---

## Installing NixOS — Step by Step

### Prerequisites

- NixOS minimal ISO written to a USB drive
- Network credentials available

---

### Step 1 — Boot the Minimal ISO

Boot from the USB drive. You land at a root shell. No graphical installer required.

---

### Step 2 — Network Setup

Connect to WiFi:

```bash
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
```

Immediately lock DNS to public resolvers:

```bash
sudo nmcli con mod "YOUR_SSID" ipv4.dns "1.1.1.1,8.8.8.8"
sudo nmcli con mod "YOUR_SSID" ipv4.ignore-auto-dns yes
sudo systemctl restart NetworkManager
```

> **NOTE: Why this matters:** Consumer routers often serve their own IP as the DNS forwarder.
>
>  This works for most applications but can fail for the Nix daemon, which makes many concurrent DNS requests.
>
>  Router DNS configs sometimes also include IPv6 link-local addresses (e.g. `fe80::1%wlp2s0`) scoped to a specific network interface — _inside the installer's chroot, that interface name does not exist, causing all DNS resolution to hang and time out_.
>
>  Setting `1.1.1.1` and `8.8.8.8` directly eliminates both failure modes.

Verify connectivity before proceeding:

```bash
ping -c 2 github.com
ping -c 2 api.github.com
```

---

### Step 3 — Disk Partitioning

> **This step will be automated via `scripts/setup-disk.sh` once complete. Until then, proceed manually.**

Identify your target disk:
```bash
lsblk
```

Partition using GPT — _one EFI System Partition, one BTRFS partition for everything else_:
```bash
gdisk /dev/sda    # replace sda with your actual disk
```

Inside `gdisk`:
```
o          → new GPT table, confirm with y
n          → new partition (EFI)
enter      → partition number 1
enter      → default first sector
+1024M      → 1GiB size
ef00       → EFI System Partition type

n          → new partition (BTRFS root)
enter      → partition number 2
enter      → default first sector
enter      → use all remaining space
8300       → Linux filesystem type

w          → write and confirm
```

Format:
```bash
mkfs.fat -F32 /dev/sda1
mkfs.btrfs -f /dev/sda2
```

> On NVMe drives, device names follow the pattern `/dev/nvme0n1p1` and `/dev/nvme0n1p2`.

---

### Step 4 — BTRFS Subvolumes

Install required tools into the live environment:
```bash
nix-shell -p git neovim
```

Clone the repository:
```bash
git clone --recurse-submodules https://github.com/CypherWhisperer/CypherOS CypherOS
```

Run the disk setup script:
```bash
bash scripts/setup-disk.sh
```

#### Subvolume Rationale

|Subvolume|Mount Point|Purpose|
|---|---|---|
|`@nixos-root`|`/`|NixOS system root|
|`@home`|`/home`|Shared home — all OSs mount this|
|`@nix-store`|`/nix`|Shared Nix store — built once, available everywhere|
|`@swap`|`/swap`|Swapfile (CoW disabled via `chattr +C`)|

The shared `@nix-store` is architecturally central: packages built once are available to every OS that mounts `/nix`. A second OS install does not re-download or re-build anything already in the store.

> **On git working tree cleanliness:** `nixos-install` requires either a clean git tree or `--impure` flag (_that tells Nix to allow dirty trees. Convenient but bypasses the reproducibility guarantee_). If you see a `git tree is dirty` error, stage your changes first: `git add -A`. This makes them visible to Nix without requiring a commit.

---

### Step 5 — Generate Hardware Configuration

```bash
sudo nixos-generate-config --root /mnt
```

This produces two files in `/mnt/etc/nixos/`:

- `hardware-configuration.nix` — machine-specific. This is what you need.
- `configuration.nix` — generic template. Ignore it; the repository provides the real one.

---

### Step 6 — Move Files Into Place

```bash
mv CypherOS /mnt/etc/nixos/CypherOS

mv /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/etc/nixos/CypherOS/hosts/nixos/

cd /mnt/etc/nixos/CypherOS && git add -A
```

---

### Step 7 — Install

```bash
nixos-install --flake /mnt/etc/nixos/CypherOS#cypher-nixos
```

Nix downloads and builds the entire system closure. Duration depends on connection quality and cache availability.

> **On nixpkgs-unstable:** Some packages on the unstable channel have no pre-built binary in `cache.nixos.org` yet. For these, Nix falls back to building from source. This is why builds on unstable can occasionally take significantly longer. The `fallback = false` setting in `configuration.nix` prevents silent source builds and will error instead — see [INC-2026-04-15-001](https://claude.ai/chat/docs/incidents/INC-2026-04-15-001.md) for the full context.

When the install completes, set a root password when prompted.

---

### Step 8 — Set User Password

Before rebooting, set the password for `cypher-whisperer`:

```bash
nixos-enter --root /mnt
passwd cypher-whisperer
exit
```

> **NOTE:** NixOS does not set a default password for declared users. Skipping this step locks the account. If you miss it: at GDM, hit `Ctrl+Alt+F2` to drop into a TTY, log in as root, then `passwd cypher-whisperer`.

---

### Step 9 — Reboot
```bash
reboot
```

Remove the USB drive when the screen goes black. The system boots into GDM.

---

### Step 10 — Post-Boot

Any configuration changes can be applied without rebooting:
```bash
sudo nixos-rebuild switch --flake /etc/nixos/CypherOS#cypher-nixos
```

---

## Generations and Storage

NixOS builds are additive and use hard links extensively. When you rebuild after changing one package, only that package's new derivation is added to the store — _unchanged packages are shared between generations via hard links and consume no additional space_. A 20GB system does not become 40GB after one rebuild.

Old generations hold references to packages removed in newer builds. Running `nix-collect-garbage -d` removes all old generation symlinks and then frees any store paths no longer referenced by any generation. This is safe to run at any time.

---

## Secrets and SSH Keys

SSH private keys (`~/.ssh/id_ed25519`, etc.) are **never tracked in this repository**. The repository manages the SSH _configuration_ (`~/.ssh/config`) declaratively via `programs.ssh` in Home Manager. The keys themselves live in `~/.ssh/` on the `@home` BTRFS subvolume.

Because `@home` is shared across all OSs, SSH keys generated once are automatically available on every OS that mounts it — no copying or re-generation required.

The `identity/shadow` file is gitignored — _it contains password hashes_.

---

## `flake.lock` — Reproducibility Pin

The `flake.lock` file pins the exact commit revision of every flake input (`nixpkgs`, `home-manager`, and any future inputs). It is the mechanism that makes the configuration reproducible. Two machines applying the same flake with the same `flake.lock` get identical results.

To pull in newer versions:
```bash
cd /path/to/CypherOS
nix flake update --extra-experimental-features "nix-command flakes"
git add flake.lock
git commit -m "chore(flake): update flake inputs $(date +%Y-%m-%d)"
```
