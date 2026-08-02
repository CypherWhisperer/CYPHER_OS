# Runbook: Proton Mail Bridge — first-boot initialization

**Applies to:** Any fresh NixOS build with `cypher-os.apps.mail.protonBridge.enable = true`
**Frequency:** Once per user account, per machine
**Estimated time:** ~5 minutes

---

## Context

Proton Mail Bridge stores your Proton session token in GNOME Keyring. On first boot, that token does not exist yet — Bridge has never authenticated. This one-time ceremony creates it. All subsequent boots are automatic.

This is not a deficiency of the declarative setup. It is the honest operational boundary between what Nix can configure (preferences, services, packages) and what requires a live authentication handshake with Proton's servers.

---

## Prerequisites

- `cypher-os.apps.mail.protonBridge.enable = true` is set and the system has been rebuilt
- `cypher-os.apps.mail.thunderbird.enable = true` and `protonSupport = true`
- GNOME session is active (GNOME Keyring must be unlocked)
- Network is up

---

## Steps

### 1. Verify the Bridge service unit exists

```bash
systemctl --user status protonmail-bridge
```

Expected: the unit is present but likely `inactive (dead)` — it has never authenticated and will restart-loop if started before the ceremony. That is fine.

---

### 2. Start Bridge in CLI mode for interactive login

```bash
protonmail-bridge --cli
```

This opens an interactive prompt. At the `>>>` prompt:

```
>>> login
```

Follow the prompts:

- Enter your Proton Mail username
- Enter your Proton Mail password
- Complete any two-factor authentication step Proton requires

Bridge will authenticate, store the session token in GNOME Keyring, and display the generated **app-password** for this machine. **Copy this app-password** — you will need it in step 4.

Exit the CLI:

```
>>> quit
```

---

### 3. Start the Bridge service

```bash
systemctl --user start protonmail-bridge
```

Verify it is running:

```bash
systemctl --user status protonmail-bridge
```

Expected: `active (running)`. If it fails, check the journal:

```bash
journalctl --user -u protonmail-bridge -n 50
```

---

### 4. Add your account in Thunderbird

Open Thunderbird. Add an account manually with the following settings:

|Field|Value|
|---|---|
|IMAP server|`127.0.0.1`|
|IMAP port|`1143`|
|SMTP server|`127.0.0.1`|
|SMTP port|`1025`|
|Username|Your Proton Mail address|
|Password|The **app-password** from step 2|
|Security|None (loopback — intentional)|

> **Note:** The connection is to `localhost`, not Proton's servers. The absence of TLS here is correct and expected — Bridge encrypts/decrypts traffic on your behalf before it ever leaves the machine.

---

### 5. Verify mail loads

Send yourself a test email or wait for the inbox to sync. If messages appear, the ceremony is complete.

---

## Subsequent boots

After the ceremony, no action is required:

1. GNOME Keyring is unlocked by PAM at login
2. The `protonmail-bridge` systemd user service starts automatically
3. Bridge retrieves its session token from the keyring
4. Thunderbird connects to `127.0.0.1:1143/1025` as configured

---

## Troubleshooting

**Bridge starts then exits with a keyring error:**
GNOME Keyring may not have been unlocked before Bridge started. Ensure `security.pam.services.login.enableGnomeKeyring = true` is set in `proton-bridge-system.nix` and rebuild. Also verify `services.gnome.gnome-keyring.enable = true`.

**Bridge is running but Thunderbird cannot connect:**
Check that Thunderbird's auth method preferences are set correctly (`mail.server.default.authMethod = 4`). These are written by `thunderbird-hm.nix` when `protonSupport = true`. If the preference is wrong, `about:config` in Thunderbird will show the current value.

**The app-password was not saved:**
Run `protonmail-bridge --cli` again, log in, and retrieve it from:

```
>>> info
```

**Non-GNOME DE (Hyprland, KDE Plasma):**
GNOME Keyring may not be present or may start differently. The Bridge service's `After = gnome-keyring-daemon.service` dependency may not resolve. Review the DE-specific keyring setup before enabling Bridge on non-GNOME CypherOS lenses.

---

<!-- METADATA
Created: 2025-05-26
Last updated: 2025-05-26
Tested by: Cypher Whisperer
-->
