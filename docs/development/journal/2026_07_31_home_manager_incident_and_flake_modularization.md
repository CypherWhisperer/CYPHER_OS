# 2026_07_31 Home Manager Boot Failure, Split Decision, and Flake Modularization

**Date:** 2026-07-31
**Duration:** Not precisely tracked — *spans multiple sittings between 2026-07-27 (first observed failure) and 2026-07-31 (resolution confirmed)*
**Repos touched:** CypherOS
**Modules touched:**
1. `flake.nix`
2. `flake/*` *(new)*
3. `hosts/nixos/configuration.nix`
4. `modules/home/default.nix`
5. `modules/home/gc-hm.nix` *(new)*
6. `modules/apps/productivity/claude.nix` *(diagnostic only)*
7. `modules/apps/productivity/obsidian.nix` *(diagnostic only)*
8. `modules/apps/productivity/d2-hm.nix` *(diagnostic only)*
**Phase:** GNOME lens stabilization

---

## What I Worked On

Chased a recurring `Failed to Start Home Manager Service` error seen in boot logs, which turned out to be blocking Home Manager's dotfile/session-variable/activation-script propagation on every boot while package installs kept succeeding — _the D2 system-wide setup session that surfaced this was the trigger._ 

Investigation led into the NixOS-module-vs-standalone `pkgs` divergence, a decision on whether to actually split HM from `nixos-rebuild`, and a flake modularization pass.

---

## What Got Done

1. Root-caused the boot-time failure of `home-manager-cypher\x2dwhisperer.service` to a stale `.hm-bak` backup file for `claude_desktop_config.json`, perpetuated by Claude Desktop rewriting that file at runtime
  
2. Cleared the stale backup, restarted the unit, confirmed clean post-reboot *(`active (exited)`, `status=0/SUCCESS`)*
  
3. Separately diagnosed and cleared a dangling symlink at `~/.config/gtk-4.0/assets` blocking the standalone `home-manager switch` path
  
4. Diagnosed the `pkgs.claude-desktop` "attribute missing" error as two independent `pkgs` instantiations in `flake.nix` *(module-level overlays for `nixosConfigurations` vs. top-level `let pkgs` for `homeConfigurations`)* with drifted overlay lists
  
5. Modularized `flake.nix` into `flake/{default,nixpkgs-config,hosts,home-configurations,devshells}.nix`, with overlays and `nixpkgs.config` centralized in `flake/nixpkgs-config.nix` as a single source of truth consumed by both evaluation paths
  
6. Verified the refactor via `nix flake check`, `nixos-rebuild boot --install-bootloader`, `home-manager switch -b hm-bk`, and a post-reboot `systemctl status` check
  
7. Selected `services.home-manager.autoExpire` for HM generation pruning *(complementing, not duplicating, the existing `nix.gc`),* placed in new `modules/home/gc-hm.nix`, imported via `modules/home/default.nix`

---

## Key Decisions Made

1. **Overlays/nixpkgs-config single source of truth:** 
    - one `flake/nixpkgs-config.nix` function of `inputs`, consumed by both `nixosConfigurations` and `homeConfigurations` — *closes the `claude-desktop` divergence class of bug for any future overlay, not just this one.*
      
2. **`flake.nix` modularization:** 
    - split into a `flake/` directory *(`default.nix` as composition point, `hosts.nix`, `home-configurations.nix`, `devshells.nix`, `nixpkgs-config.nix`).*
    - `flake-parts` explicitly deferred for now.
      
3. **HM stays NixOS-module-integrated — *no full split into independent `nixos-rebuild`/`home-manager` flows.*** 
    - The original session goal assumed this needed deliberate architectural separation; it turned out both commands were already independently usable *(`nixos-rebuild` drives both via the module; `home-manager switch --flake .#...@cypher-nixos` already works standalone).* 
    - With the boot-failure bug fixed, the motivating reason for a full split was gone, so the combined setup was kept as-is.
      
4. **Username rename settled on `cypher_whisperer`** 
    - *(underscore, not hyphen)* — avoids systemd's `\x2d` escaping on the generated unit name going forward.
    - UID (1000) and home directory path (`/home/cypher-whisperer`) to remain unchanged; only the username string and dependent references change.
      
5. **`services.home-manager.autoExpire`** 
    - adopted with `store.cleanup = false` — *deliberately left off to avoid double-running `nix-collect-garbage` alongside the existing system-level `nix.gc`.*

---

## Where I Got Stuck

Systemd's automatic escaping of the literal hyphen in `cypher-whisperer` into `\x2d` *(since `-` is also the structural separator in `home-manager-<user>.service`)* silently broke the first round of `systemctl status`/`journalctl -u` diagnostics run against the unescaped name — *both returned as if the unit didn't exist / had no logs, costing a full diagnostic round before the correct escaped name was used.*

Separately, the D2 propagation symptom initially looked isolated to that one module until the `useUserPackages` package-delivery-independent-of-activation-success mechanism was understood — *packages installing fine while everything else silently failed made the actual scope of the bug non-obvious at first.*

---

## What I Learned

`useUserPackages = true` means package presence after a rebuild is not proof Home Manager fully applied — the activation script *(dotfiles, session variables, hooks)* is a separate success/failure path from package delivery, and only `systemctl status` on the actual unit confirms both.

Any flake exposing both a NixOS-module-integrated HM path and a standalone `homeConfigurations` path will silently drift in `pkgs`/overlays unless explicitly unified — *this is systemic, not incidental, and worth checking for in any future multi-context flake design (e.g. eventually adding the Arch/Debian/Fedora/openSUSE lenses as real `homeConfigurations` entries).*

---

## Open Questions

1. Whether to adopt `home-manager.backupCommand` (e.g. via `trash-cli`) instead of `backupFileExtension`, since a `.hm-bak` sibling can itself go stale and re-trigger this exact failure mode
   
2. When/whether to bump `home.stateVersion` past `"24.11"` toward `"26.05"`, given the batch of accumulated deprecation warnings *(`programs.vscode.extensions`, `programs.ssh.matchBlocks`, `programs.firefox.configPath`, `xdg.userDirs.*`, `programs.zsh.initExtra`)* that are gated behind that bump
   
3. Whether to adopt `home-manager.sharedModules` once a second HM user exists under `home-manager.users.*` *(no benefit with only `cypher_whisperer` today)*
   
4. Whether `flake-parts` becomes warranted once multiple architectures/hosts are actually live, versus the current plain-file `flake/` split

---

## Next Session

1. Execute the username rename (`cypher-whisperer` → `cypher_whisperer`) via `nixos-rebuild boot` + reboot validation, following the file-by-file checklist already drafted (`modules/users/`, `hosts/nixos/configuration.nix` trusted-users, `flake/hosts.nix`, `flake/home-configurations.nix`, AccountsService avatar paths). 

2. Add the `hms` zsh alias/function once the username is final. 
3. Then produce the remaining deliverables: ADRs for the username rename, overlays/nixpkgs-config SSOT, `flake.nix` modularization, and the HM/NixOS-integration decision; module documentation for `modules/home/{default,gc-hm}.nix` and `flake.nix`/`flake/*.nix`.

---

<!-- 
Commit range (fill in after session): 
CypherOS: [short hash] → [short hash] 
-->