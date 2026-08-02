# Proton Bridge — `proton-bridge-hm.nix`

> Installs the Proton Mail Bridge package and registers it as a persistent systemd user service that exposes local IMAP and SMTP endpoints to Thunderbird.

**Module path:** `modules/apps/mail/proton-bridge-hm.nix`
**Evaluation context:** `Home Manager`
**Status:** `In Development`
**Last reviewed:** `2025-05-26`

---

## Responsibility

**Does:**

- Adds `pkgs.protonmail-bridge` to `home.packages`
- Declares a `systemd.user.services.protonmail-bridge` unit that runs Bridge headlessly on login and restarts on failure

**Does not:**

- Enable or configure GNOME Keyring — that is a system-level concern handled in `proton-bridge-system.nix`
- Configure Thunderbird account details — deferred to the first-boot ceremony (see runbook)
- Manage secrets or Proton credentials — Bridge handles credential storage via the Secret Service API at runtime

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.mail.protonBridge`|
|Imports `options.nix`|Yes — required|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.enable && cypher-os.apps.mail.enable && cypher-os.apps.mail.protonBridge.enable)`|
|Profile default|`lib.mkDefault false` — opt-in only|

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A list passed to the module's top-level `imports` attribute.

**What does it do?** Merges `modules/apps/mail/options.nix` and `modules/apps/options.nix` into this file's evaluation context, making `cypher-os.apps.enable` and all `cypher-os.apps.mail.*` option declarations visible.

**Why is it here?** These are Home Manager-context files. Without explicitly them, any reference to `cypher-os.apps.enable` and `cypher-os.apps.mail.protonBridge.*` would throw an undefined option error at eval time, because HM and NixOS evaluate in separate contexts and option declarations do not cross that boundary automatically.

```nix
imports = [
  ./options.nix,
  ../options.nix
];
```

---

### Block 2 — Kill-switch guard

**What is this?** A `lib.mkIf` expression wrapping the entire `config` attrset.

**What does it do?** Makes the entire module a no-op unless the three-level enable chain is satisfied: `cypher-os.apps.enable`, `cypher-os.apps.mail.enable`, and `cypher-os.apps.mail.protonBridge.enable`.

**Why is it here?** Follows the CypherOS pattern of hierarchical kill-switches. A user disabling `cypher-os.apps.mail.enable` should disable all mail tooling — Bridge and Thunderbird alike — without needing to touch each sub-module individually.

```nix
config = mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.mail.enable && cfg.enable) {
  ...
};
```

---

### Block 3 — `home.packages`

**What is this?** An addition to the HM-managed package list.

**What does it do?** Installs the `protonmail-bridge` binary into the user's environment, making `protonmail-bridge --cli` available for the one-time interactive login ceremony.

**Why is it here?** The package must be present for both the systemd service (which references its store path in `ExecStart`) and for the manual CLI step on first boot. Without it, the service unit would point to a non-existent path.

```nix
home.packages = [ pkgs.protonmail-bridge ];
```

---

### Block 4 — `systemd.user.services.protonmail-bridge`

**What is this?** A systemd user service unit declaration managed by Home Manager.

**What does it do?** Registers a persistent background service that starts Bridge headlessly on login, restarts it on failure with a 5-second backoff, and waits for both network connectivity and the GNOME Keyring daemon before starting.

**Why is it here?** Bridge must be running continuously for Thunderbird to reach Proton Mail. A user service (not a system service) is the correct scope — Bridge authenticates as a specific user and stores credentials in that user's keyring. The `After`/`Wants` ordering on `network-online.target` and `gnome-keyring-daemon.service` prevents a race condition where Bridge starts before it can reach Proton's servers or before the keyring is ready to supply the stored session token.

```nix
systemd.user.services.protonmail-bridge = {
  Unit = {
    Description = "Proton Mail Bridge local IMAP/SMTP proxy";
    After = [ "network-online.target" "gnome-keyring-daemon.service" ];
    Wants = [ "network-online.target" ];
  };
  Service = {
    ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --no-window";
    Restart = "on-failure";
    RestartSec = "5s";
  };
  Install.WantedBy = [ "default.target" ];
};
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares all `cypher-os.apps.mail.*` options; required for this file to reference them without eval errors

**Home Manager options set by this file:**

- `home.packages` — adds `protonmail-bridge`
- `systemd.user.services.protonmail-bridge` — declares the Bridge service unit

**nixpkgs packages required:**

- `pkgs.protonmail-bridge` — the Bridge binary; path is interpolated into `ExecStart`

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Effect when `true` / set|
|---|---|---|
|`cypher-os.apps.enable`|`bool`|Top-level kill-switch for all `cypher-os.apps.*` modules|
|`cypher-os.apps.mail.enable`|`bool`|Kill-switch for all mail sub-modules|
|`cypher-os.apps.mail.protonBridge.enable`|`bool`|Activates this file's `config` block|
|`cypher-os.apps.mail.protonBridge.imapPort`|`port`|Declared in `options.nix`; not yet consumed here — reserved for future use in Thunderbird account wiring|
|`cypher-os.apps.mail.protonBridge.smtpPort`|`port`|Same — reserved|

---

## Design Notes

- `--no-window` is intentional: it runs Bridge as a pure daemon with no system tray dependency, which is correct for a headless/reproducible setup. The GUI variant (`protonmail-bridge-gui`) is a separate nixpkgs package and is not used here.
- `imapPort` and `smtpPort` options exist in `options.nix` but are not yet wired into the service. They are reserved for when account configuration is added to `thunderbird-hm.nix` (Phase 2, post-secrets-management).
- The `Restart = "on-failure"` policy is intentional. Bridge occasionally loses its connection to Proton's servers; silent restart is preferable to a dead service requiring manual intervention.

---

## Known Limitations

- The one-time interactive login ceremony (`protonmail-bridge --cli`) cannot be automated without a secrets management layer. See the first-boot runbook.
- `gnome-keyring-daemon.service` ordering works correctly on GNOME/GDM. On other DEs (Hyprland, KDE Plasma) the keyring daemon may not be present or may use a different service name — **this must be revisited before enabling Bridge on non-GNOME lenses of CypherOS**.
- `imapPort` and `smtpPort` are not yet consumed by any other module; Bridge always starts on its compiled-in defaults (1143/1025) regardless of what those options are set to. Wiring them into Bridge's config requires a config file or CLI flags that Bridge's current nixpkgs derivation does not expose declaratively.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|`proton-bridge-system.nix`|
|Profile default set in|`modules/profile/default.nix`|
|First-boot runbook|`docs/runbooks/proton-bridge-first-boot.md`|

---

<!-- METADATA
Module: modules/apps/mail/proton-bridge-hm.nix
Context: Home Manager
Created: 2025-05-26
Last updated: 2025-05-26
-->
