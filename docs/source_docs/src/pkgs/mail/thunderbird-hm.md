# Thunderbird — `thunderbird-hm.nix`

> Configures the Thunderbird email client declaratively: privacy-hardened global and per-profile preferences, catppuccin theming via `catppuccin/nix`, and optional Proton Bridge connection settings — with account wiring intentionally deferred.

**Module path:** `modules/apps/mail/thunderbird-hm.nix`
**Evaluation context:** `Home Manager`
**Status:** `In Development`
**Last reviewed:** `2025-05-26`

---

## Responsibility

**Does:**

- Enables `programs.thunderbird` with a single named profile
- Applies privacy-focused global preferences via `programs.thunderbird.settings` (telemetry off, remote content blocked, plain text compose)
- Applies per-profile preferences via `programs.thunderbird.profiles.<name>.settings`
- Enables the catppuccin Thunderbird theme via `catppuccin.thunderbird`, inheriting the global flavor and accent with an optional per-instance override
- Conditionally adds Proton Bridge auth preferences when `protonSupport` is enabled
- Asserts that `protonBridge.enable = true` when `protonSupport` is requested

**Does not:**

- Declare any `cypher-os.*` options — see `options.nix`
- Handle system-level concerns (GNOME Keyring, PAM) — see `proton-bridge-system.nix`
- Wire Thunderbird accounts (`accounts.email`) — intentionally deferred pending secrets management design
- Install extensions beyond the catppuccin theme — HM has no declarative extension installer for Thunderbird yet

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.mail.thunderbird`|
|Imports `options.nix`|Yes — required|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.enable && cypher-os.apps.mail.enable && cypher-os.apps.mail.thunderbird.enable)`|
|Profile default|`lib.mkDefault true` set in `modules/profile/default.nix`|

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A list passed to the module's top-level `imports` attribute.

**What does it do?** Merges `modules/apps/mail/options.nix` and `modules/apps/options.nix` into this file's Home Manager evaluation context, making all `cypher-os.apps.enable` and `cypher-os.apps.mail.*` option declarations visible.

**Why is it here?** Without this import, any reference to `cypher-os.apps.enable`, `cypher-os.apps.mail.thunderbird.*` or `cypher-os.apps.mail.protonBridge.*` would produce an undefined option error at eval time.

```nix
imports = [
  ./options.nix
  ../options.nix
];
```

---

### Block 2 — Kill-switch guard

**What is this?** A `lib.mkIf` expression wrapping the entire `config` attrset.

**What does it do?** Activates this module only when the three-level enable chain is satisfied: `cypher-os.apps.enable`, `cypher-os.apps.mail.enable`, and `cypher-os.apps.mail.thunderbird.enable`.

**Why is it here?** Consistent with the CypherOS hierarchical kill-switch pattern. Disabling `cypher-os.apps.mail.enable` suppresses both Thunderbird and Bridge in one toggle.

```nix
config = mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.mail.enable && cfg.enable) {
  ...
};
```

---

### Block 3 — `assertions`

**What is this?** A list of NixOS/HM assertion attrsets evaluated before the build proceeds.

**What does it do?** Fails the build with a descriptive message if `protonSupport = true` is set without `protonBridge.enable = true`. This prevents Thunderbird from being configured to talk to a Bridge that isn't running.

**Why is it here?** `protonSupport` sets auth preferences that only make sense when Bridge is active on localhost. Without the assertion, a user could enable `protonSupport` in isolation and end up with a Thunderbird configuration that silently fails to connect. The assertion surfaces this misconfiguration at eval time rather than at runtime.

```nix
assertions = [
  {
    assertion = !cfg.protonSupport || bridgeCfg.enable;
    message = ''
      cypher-os.apps.mail.thunderbird.protonSupport = true requires
      cypher-os.apps.mail.protonBridge.enable = true.
    '';
  }
];
```

---

### Block 4 — `catppuccin.thunderbird`

**What is this?** Configuration for the `catppuccin/nix` Thunderbird HM module.

**What does it do?** Instructs `catppuccin/nix` to place the Thunderbird catppuccin theme XPI into the profile's extensions directory at derivation time. The theme is activated by setting the selected theme UUID in the profile's `user.js` — `catppuccin/nix` handles both steps.

**Why is it here?** Thunderbird themes are WebExtension XPI packages. HM has no native declarative extension installer for Thunderbird (unlike Firefox), but `catppuccin/nix` works around this via `home.file` placement under the hood. Using `catppuccin/nix` means the theme integrates with the global `catppuccin.flavor` and `catppuccin.accent` SSOT, and the accent can be overridden per-instance via `cfg.catppuccinAccent` without touching the global.

```nix
catppuccin.thunderbird = {
  enable = true;
  flavor = config.catppuccin.flavor;
  accent = if cfg.catppuccinAccent != null
           then cfg.catppuccinAccent
           else config.catppuccin.accent;
};
```

---

### Block 5 — `programs.thunderbird.settings` (global preferences)

**What is this?** An attribute set of Thunderbird preference keys and values written into a global `user.js` applied across all profiles.

**What does it do?** Disables telemetry and data submission, enables `userChrome.css` stylesheet loading, sets compact UI density, and suppresses the first-run rights nag screen.

**Why is it here?** These are preferences that apply regardless of which profile is active and do not vary per-account. Placing them at the global level (rather than inside `profiles.<name>.settings`) avoids repeating them across multiple profiles if the configuration is ever extended to support more than one.

```nix
settings = {
  "datareporting.healthreport.uploadEnabled"           = false;
  "datareporting.policy.dataSubmissionEnabled"         = false;
  "toolkit.telemetry.enabled"                          = false;
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "mail.uidensity"      = 0;
  "mail.rights.version" = 1;
};
```

---

### Block 6 — `programs.thunderbird.profiles.<name>.settings` base preferences

**What is this?** An attribute set of per-profile preferences, wrapped in `mkMerge` to allow conditional extension.

**What does it do?** Sets plain-text composition, tab-based message opening, threaded view, an ISO-adjacent date format, and remote image blocking. These are applied only to the `cfg.profile` profile (default: `"cypher"`).

**Why is it here?** These preferences are profile-specific defaults — reasonable for the CypherOS primary profile but not necessarily universal. `mkMerge` is used rather than a plain attrset because a second attrset (the Proton Bridge block) needs to be conditionally merged in at the same level without nesting.

```nix
settings = mkMerge [
  {
    "mail.compose.default_to_paragraph"             = false;
    "mail.html_compose"                             = false;
    "mail.openMessageBehavior"                      = 0;
    "mail.thread.sort_order"                        = true;
    "mail.date_format"                              = 5;
    "mailnews.message_display.disable_remote_image" = true;
  }
  ...
];
```

---

### Block 7 — `programs.thunderbird.profiles.<name>.settings` Proton Bridge preferences

**What is this?** A second attrset inside `mkMerge`, gated by `mkIf cfg.protonSupport`.

**What does it do?** Sets `authMethod = 4` (normal password) for both the default IMAP server and the SMTP server. This tells Thunderbird to accept plain-password authentication over the loopback interface, which is what Bridge's app-password flow requires.

**Why is it here?** Bridge presents a local IMAP/SMTP server that uses a generated app-password over an unencrypted loopback connection. Thunderbird's default auth settings reject this. These preferences are conditionally merged only when `protonSupport = true` to avoid setting loopback-auth preferences on configurations that don't use Bridge.

```nix
(mkIf cfg.protonSupport {
  "mail.server.default.authMethod"     = 4;
  "mail.smtpserver.default.authMethod" = 4;
})
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares all `cypher-os.apps.mail.*` options

**Home Manager options set by this file:**

- `catppuccin.thunderbird` — theme placement via `catppuccin/nix`
- `programs.thunderbird.enable` — activates the HM Thunderbird module
- `programs.thunderbird.settings` — global `user.js` preferences
- `programs.thunderbird.profiles.<name>.settings` — per-profile `user.js` preferences

**nixpkgs packages required:**

- `pkgs.thunderbird` — pulled in implicitly by `programs.thunderbird.enable = true`

**External flake inputs used:**

- `catppuccin/nix` — `catppuccin.homeManagerModules.catppuccin` must be in the HM imports for `catppuccin.thunderbird` to be a valid option

---

## Option Surface

|Option|Type|Effect when `true` / set|
|---|---|---|
|`cypher-os.apps.enable`|`bool`|Top-level kill-switch for all `cypher-os.apps.*` modules|
|`cypher-os.apps.mail.enable`|`bool`|Kill-switch for all mail sub-modules|
|`cypher-os.apps.mail.thunderbird.enable`|`bool`|Activates this file's `config` block|
|`cypher-os.apps.mail.thunderbird.profile`|`str`|Names the primary Thunderbird profile; defaults to `"cypher"`|
|`cypher-os.apps.mail.thunderbird.catppuccinAccent`|`nullOr enum`|Overrides the theme accent for Thunderbird; `null` inherits `catppuccin.accent`|
|`cypher-os.apps.mail.thunderbird.protonSupport`|`bool`|Merges Bridge auth preferences and asserts `protonBridge.enable`|

---

## Design Notes

- Account configuration (`accounts.email`, IMAP/SMTP server wiring, contact/calendar sync) is intentionally absent. Hard-coding addresses in the Nix store leaks identity into a world-readable path and destroys flexibility. The deferred path is: `accounts.email` as structural SSOT with passwords sourced via `passwordCommand` pointing at a sops-nix or age secret. This is a Phase 2 concern.
- `mkMerge` on `profiles.<name>.settings` is the correct approach for conditional preference injection. Using `lib.optionalAttrs` would also work but `mkMerge [ base (mkIf cond extra) ]` reads more clearly as "these are the base prefs, and optionally these are added."
- The `catppuccin/nix` thunderbird module places the XPI via `home.file` at derivation time. No `userChrome.css` is needed for the base theme. `toolkit.legacyUserProfileCustomizations.stylesheets = true` is set at the global level to allow structural CSS tweaks in future without requiring another preference change.
- The new `catppuccin.*` namespace (e.g. `catppuccin.thunderbird.enable` rather than `programs.thunderbird.catppuccin.enable`) is used from the start, consistent with the pre-2.0.0 migration. The old aliases remain temporarily but will be removed in `catppuccin/nix` 2.0.0.

_See the open HM issue ([nix-community/home-manager#5654](https://github.com/nix-community/home-manager/issues/5654)) for progress on declarative Thunderbird extension management. When that lands, extensions beyond the catppuccin theme can be added here._

---

## Known Limitations

- Extension management beyond the catppuccin theme is not declarative. Any additional extensions (Lightning calendar, etc.) must be installed manually through Thunderbird's UI on first run. Track the linked HM issue.
- `authMethod = 4` is applied to `mail.server.default` and `mail.smtpserver.default`. If Thunderbird is later configured with multiple accounts, per-server auth method preferences may need to be set more precisely than the `default.*` keys allow.
- The `catppuccin/nix` Thunderbird module carries a minimum HM version assertion. On `nixos-unstable` this is unlikely to fire, but the first build should be watched for an eval-time warning about version compatibility.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|`N/A — no system.nix needed for Thunderbird`|
|Proton Bridge HM|`proton-bridge-hm.nix`|
|Proton Bridge system|`proton-bridge-system.nix`|
|Profile default set in|`modules/profile/default.nix`|
|First-boot runbook|`docs/runbooks/proton-bridge-first-boot.md`|
|HM extension issue|`https://github.com/nix-community/home-manager/issues/5654`|

---

<!-- METADATA
Module: modules/apps/mail/thunderbird-hm.nix
Context: Home Manager
Created: 2025-05-26
Last updated: 2025-05-26
-->
