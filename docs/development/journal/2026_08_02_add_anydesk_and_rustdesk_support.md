# 2026_08_02 Add AnyDesk and RustDesk Support

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-08-02
**Duration:** ~1 hour
**Repos touched:** [ CypherOS ] 
**Modules touched:** 
1. `modules/apps/productivity/anydesk-hm.nix`
2. `modules/apps/productivity/rustdesk-hm.nix`
3. `modules/apps/productivity/rustdesk-system.nix`
4. `modules/apps/productivity/options.nix`
5. `modules/profile/{default,system}.nix`
6. `hosts/nixos/configuration.nix`

---

## What I Worked On

Researched AnyDesk and RustDesk end to end — what each actually is, how they work under the hood (DeskRT codec vs. VP8/VP9/AV1, TLS+RSA vs. Ed25519, AnyDesk's closed relay network vs. RustDesk's hbbs/hbbr), what nixpkgs actually offers for each (plain unfree package for AnyDesk, a real `services.rustdesk-server` module for RustDesk), and then turned that into the `modules/apps/productivity/{anydesk,rustdesk}` module trio following the existing three-file split (`options.nix` / `hm.nix` / `system.nix`).

Also used the research pass to sanity-check two adjacent things I'd been curious about: how this category differs from Termius (GUI desktop streaming vs. plain SSH/terminal sessions), and how it differs from hardware Network KVM devices like JetKVM (agent-inside-the-OS vs. HDMI+USB dongle that works with no OS at all — BIOS flashing, dead machines, etc.). Not implemented, just wanted the mental model straight before deciding what CypherOS actually needs.

---

## What Got Done

- `modules/apps/productivity/options.nix` extended with `cypher-os.apps.productivity.{anydesk,rustdesk}` — `anydesk.enable`; `rustdesk.enable` plus a nested `rustdesk.server.{enable,openFirewall,relayHosts,signalExtraArgs,relayExtraArgs}`
  
- `modules/apps/productivity/anydesk-hm.nix` — installs `pkgs.anydesk` via Home Manager, gated on the standard `productivity.enable && anydesk.enable` guard. 
  Interactive/normal mode only — no permanent password, no systemd daemon wiring
- `modules/apps/productivity/rustdesk-hm.nix` — installs `pkgs.rustdesk-flutter` via Home Manager, same gating pattern. Works against RustDesk's public hbbs/hbbr with zero further config
  
- `modules/apps/productivity/rustdesk-system.nix` — NixOS-context module wrapping `services.rustdesk-server`, importing `options.nix` directly since NixOS's module system doesn't see HM-context option declarations otherwise. Removed the unused `pkgs` argument since the file only reads `config`/`cfg`
  
- Set `cypher-os.apps.productivity.rustdesk.server.enable = lib.mkDefault false;` in the profile — self-hosting is wired and ready but deliberately off for now

---

## Key Decisions Made

- **AnyDesk: interactive/normal mode only, no unattended access.** Left a comment block in `anydesk-hm.nix` spelling out exactly what enabling unattended access would require later (permanent password + explicit `systemd.packages`/`systemd.services.anydesk` wiring at the system level, since nixpkgs ships the unit file but doesn't register it) — so future-me doesn't have to re-derive it from scratch, but it's not live today
  
- **RustDesk client and server are decoupled on purpose.** The HM client module has no dependency on the system server module being enabled, and vice versa — the client just points at whichever relay it's configured for (public by default, or my own once `server.enable` flips true). No automatic wiring between the two; that's a manual in-app config step
  
- **RustDesk server: built but not turned on yet.** Wanted the module in place and correct before actually exposing anything — `mkDefault false` keeps it inert until I have a real reason (and a real `relayHosts` target) to flip it

---

## Where I Got Stuck

Nothing blocked — this was mostly research-then-encode. The one thing worth flagging for later: `relayHosts` has no sane default (empty list), so if `server.enable` ever flips true without also setting `relayHosts`, hbbs will start but won't advertise anywhere useful. Not a bug, just a footgun to remember.

---

## What I Learned

- nixpkgs treats AnyDesk and RustDesk very differently: AnyDesk is just a package (unfree, no service module — the systemd unit it ships isn't wired into `systemd.services` automatically), while RustDesk has a proper first-class `services.rustdesk-server` module. That asymmetry alone made the module design cleaner for RustDesk than AnyDesk
  
- RustDesk Server Pro is a separate closed-source binary from the OSS `hbbs`/`hbbr` — "self-hosted" doesn't imply "open source" there. Worth remembering if I ever want the web console/2FA/centralized device management features, since that's a different (paid, proprietary) artifact entirely, not a config flag on what's declared in `rustdesk-system.nix`
  
- The category this whole module group lives in (software remote-desktop) is genuinely distinct from both Termius-style SSH tooling (text session, no video/input-injection layer) and hardware Network KVM (operates below the OS entirely — useful for BIOS access or a dead machine, which no software agent can ever do since it needs the target OS already running)

---

## Open Questions

- If/when `rustdesk.server.enable` flips true: self-host on an existing always-on box, or a dedicated VPS? Depends on whether reachability (static IP, uptime) is already solved by something in the current homelab, or whether Tailscale is enough to skip public exposure entirely *(no `openFirewall` needed if every client is already on the tailnet)*
  
- Whether AnyDesk stays installed long-term or gets dropped in favor of RustDesk-only, now that the RustDesk path is fully wired and open-source end to end

---

## Next Session

Nothing queued yet — this module pair is done and inert until a real need for self-hosting or unattended access shows up.

---

<!-- 
Commit range (fill in after session): 
CypherOS: [short hash] → [short hash] 
-->