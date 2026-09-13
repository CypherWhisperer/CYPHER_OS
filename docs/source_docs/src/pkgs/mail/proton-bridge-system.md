# Proton Bridge — `proton-bridge-system.nix`

> Enables the GNOME Keyring Secret Service daemon and configures PAM to unlock the login keyring on session start, satisfying Bridge's credential storage dependency at the system level.

**Module path:** `modules/apps/mail/proton-bridge-system.nix`
**Evaluation context:** `NixOS system`
**Status:** `In Development`
**Last reviewed:** `2025-05-27`

---
## Responsibility

**Does:**

- Enables `services.gnome.gnome-keyring` (_the system-level GNOME Keyring daemon_)
- Enables `security.pam.services.login.enableGnomeKeyring` so the login keyring is unlocked automatically on session start

**Does not:**

- Install any packages — _the Bridge binary lives in `proton-bridge-hm.nix`_
- Declare the systemd user service — _that is also in `proton-bridge-hm.nix`_
- Configure Thunderbird or any other mail client

---
## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`nixosModules`|
|Options namespace|`cypher-os.apps.mail.protonBridge`|
|Imports `options.nix`|Yes — required|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.enable && cypher-os.apps.mail.enable && cypher-os.apps.mail.protonBridge.enable)`|
|Profile default|`lib.mkDefault false` — opt-in only|

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A list passed to the module's top-level `imports` attribute.

**What does it do?** Merges `modules/apps/mail/options.nix` and `modules/apps/options.nix` into the NixOS evaluation context so `cypher-os.apps.enable` and `cypher-os.apps.mail.protonBridge.*` options are visible to this file.

**Why is it here?** NixOS-context modules cannot see HM-context option declarations. `options.nix` must be explicitly imported in every NixOS module that references `cypher-os.*` options, or any reference to those options will throw an undefined option error at eval time.

```nix
imports = [
  ./options.nix
  ../options.nix
];
```

---

### Block 2 — Kill-switch guard

**What is this?** A `lib.mkIf` expression wrapping the entire `config` attrset.

**What does it do?** Makes this file's system-level changes a no-op unless the three-level enable chain is satisfied, mirroring the guard in `proton-bridge-hm.nix`.

**Why is it here?** System configuration is expensive — enabling `gnome-keyring` and modifying PAM on a host that isn't using Bridge would be unnecessary and potentially confusing. The guard ensures these changes are applied only when Bridge is genuinely enabled.

```nix

config = mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.mail.enable && cfg.enable) {
  ...
};
```

---

### Block 3 — `services.gnome.gnome-keyring.enable`

**What is this?** A NixOS system option that enables the GNOME Keyring daemon.

**What does it do?** Starts `gnome-keyring-daemon` as a D-Bus session service, which implements the freedesktop.org Secret Service API on `org.freedesktop.secrets`.

**Why is it here?** Proton Mail Bridge uses the Secret Service API to store and retrieve its Proton session token. Without a running Secret Service implementation, Bridge cannot persist credentials across reboots and will require interactive re-authentication on every boot. GNOME Keyring is the only currently-supported Secret Service backend for NixOS/GNOME without significant additional configuration.

```nix
services.gnome.gnome-keyring.enable = true;
```

---

### Block 4 — `security.pam.services.login.enableGnomeKeyring`

**What is this?** A PAM service option that inserts the `pam_gnome_keyring.so` module into the login PAM stack.

**What does it do?** Automatically unlocks the user's GNOME Keyring login keyring when the user authenticates at login time. After the first interactive Bridge login ceremony, Bridge's session token is stored in this keyring — PAM unlock means subsequent boots are fully automatic from Bridge's perspective.

**Why is it here?** Without PAM integration, the keyring remains locked after login and Bridge would fail to retrieve its stored token, falling back to requiring interactive authentication. This is the standard pattern for any application that reads from the GNOME Keyring at service startup.

```nix
security.pam.services.login.enableGnomeKeyring = true;
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares all `cypher-os.apps.mail.*` options; required for this file to evaluate without errors in the NixOS context

**NixOS options set by this file:**

- `services.gnome.gnome-keyring.enable` — enables the keyring daemon
- `security.pam.services.login.enableGnomeKeyring` — inserts the PAM keyring unlock module

**nixpkgs packages required:**

- None directly — `gnome-keyring` is pulled in transitively by `services.gnome.gnome-keyring.enable`

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Effect when `true` / set|
|---|---|---|
|`cypher-os.apps.enable`|`bool`|Top-level kill-switch for all `cypher-os.apps.*` modules|
|`cypher-os.apps.mail.enable`|`bool`|Kill-switch for all mail sub-modules|
|`cypher-os.apps.mail.protonBridge.enable`|`bool`|Activates this file's `config` block|

---

## Design Notes

- This file exists as a separate `system.nix` precisely because `services.gnome.gnome-keyring` and `security.pam.*` are NixOS system options — they cannot be set from within a Home Manager evaluation context. This is the canonical reason for the three-file split.
- The `services.gnome.gnome-keyring.enable` option is the correct NixOS system path. The HM option `services.gnome-keyring.enable` (without the `.gnome.` namespace) is a different, Home Manager-specific option for a user-scoped service — do not conflate them.
- PAM is configured for the `login` service. If GDM is the display manager, `security.pam.services.gdm.enableGnomeKeyring = true` may also be needed depending on whether unlock is occurring at the DM level or the PAM login level. This has not been tested on the current host configuration.

---

## Known Limitations

- GNOME Keyring is the only well-supported Secret Service backend on NixOS/GNOME. When CypherOS is extended to Hyprland or KDE Plasma lenses, the keyring situation must be re-evaluated — KDE Plasma uses KWallet, which implements the same Secret Service API but requires different configuration. Bridge's compatibility with KWallet as of mid-2025 is limited.
- PAM unlock is configured for `login` only. Sessions authenticated via GDM may need an additional `gdm`-scoped PAM entry. Untested.

---

## Related

| Type                   | Reference                                   |
| ---------------------- | ------------------------------------------- |
| Options declared in    | `./options.nix`                             |
| Counterpart file       | `proton-bridge-hm.nix`                      |
| Profile default set in | `modules/profile/default.nix`               |
| First-boot runbook     | `docs/runbooks/proton-bridge-first-boot.md` |

---

<!-- METADATA
Module: modules/apps/mail/proton-bridge-system.nix
Context: NixOS system
Created: 2026-05-26
Last updated: 2026-05-27
-->
