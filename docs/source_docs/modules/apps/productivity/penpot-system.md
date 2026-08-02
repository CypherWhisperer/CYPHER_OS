<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Penpot System — `penpot-system.nix`

> _NixOS system-level prerequisites for the local Penpot instance: `/etc/hosts` entry for `design.penpot.local` and Caddy local CA trust._

**Module path:** `modules/apps/productivity/penpot-system.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2026-06-10`

---

## Responsibility

**Does:**

- Adds a `networking.hosts` entry resolving `design.penpot.local` to `127.0.0.1`, enabling browser and Penpot Desktop access to the local instance without a DNS server
- Adds Caddy's generated root certificate to `security.pki.certificateFiles`, making the system trust store accept HTTPS connections to `design.penpot.local` without browser warnings
- Imports `./options.nix` directly, since this file evaluates in the NixOS context and cannot rely on the HM `default.nix` import chain

**Does not:**

- Install or manage the Penpot Docker Compose stack — _that lives in its own repository_
- Install the Penpot Desktop client — _that is `penpot-hm.nix`'s concern_
- Set any Home Manager options

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`nixosModules`|
|Options namespace|`cypher-os.apps.productivity`|
|Imports `options.nix`|Yes — required; NixOS evaluation context cannot see the HM-side `default.nix` import chain|
|Kill-switch guard|`lib.mkIf (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.penpot.enable)`|
|Profile default|`lib.mkDefault true` set in `modules/apps/productivity/hm.nix`|

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A top-level `imports` list containing a single entry: `./options.nix`.

**What does it do?** Merges `options.nix` into this module's NixOS evaluation context. This makes `cypher-os.apps.productivity.*` option paths available so the `lib.mkIf` guard in Block 2 can read them without an "undefined option" eval error.

**Why is it here?** This file is imported directly into `hosts/nixos/configuration.nix` — the NixOS system configuration — and therefore evaluates in the NixOS module context, not the Home Manager context. The HM `default.nix` (which imports `options.nix` for all HM-context modules) is invisible here. Without this explicit import, the `cypher-os.apps.productivity.*` option namespace does not exist at NixOS evaluation time and every reference to it is a fatal eval error. Every `*-system.nix` file in CypherOS that reads `cypher-os.*` options must import `options.nix` directly for this reason.

```nix
imports = [ ./options.nix ];
```

---

### Block 2 — Kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset, conditioned on both `productivity.enable` and `penpot.enable` being `true`.

**What does it do?** When either condition is `false`, the block evaluates to `{}` — no hosts entry is written and no certificate is trusted. The system remains unaware of `design.penpot.local` until the guard is satisfied.

**Why is it here?** Standard CypherOS two-level guard applied at the NixOS layer. Keeping the Penpot-specific networking and PKI config behind this guard means disabling Penpot (`penpot.enable = false`) cleanly removes both the DNS entry and the CA trust from the running system on the next rebuild — no leftover `/etc/hosts` entries or stale trusted certificates.

```nix
config =
  lib.mkIf
    (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.penpot.enable)
    { ... };
```

---

### Block 3 — `networking.hosts`

**What is this?** An assignment to `networking.hosts`, which NixOS merges into `/etc/hosts` at activation time. The value is an attrset mapping an IP address string to a list of hostnames.

**What does it do?** Adds the line `127.0.0.1 design.penpot.local` to `/etc/hosts`. Any process on the machine that performs a DNS lookup for `design.penpot.local` — _browser, Penpot Desktop, curl_ — receives `127.0.0.1` without consulting an upstream DNS server. This is what makes `https://design.penpot.local` reachable as the entry point to the local Docker Compose Penpot instance.

**Why is it here?** The local Penpot instance runs entirely on `localhost` — _there is no external DNS entry for `design.penpot.local` and none is needed._ `/etc/hosts` is the simplest, zero-infrastructure way to establish the local domain. The upgrade path — _systemd-resolved stub zones_ — is documented in the migration note in the source file and in ADR-004 of the Penpot project (cypher-penpot). That upgrade is deferred because the `/etc/hosts` approach satisfies the current requirement without additional complexity.

```nix
networking.hosts = {
  "127.0.0.1" = [ "design.penpot.local" ];
};
```

---

### Block 4 — `security.pki.certificateFiles`

**What is this?** An assignment to `security.pki.certificateFiles`, a NixOS option that appends additional X.509 certificate files to the system trust store. The value is a list containing one absolute path to Caddy's generated root certificate.

**What does it do?** Adds Caddy's local CA root certificate to the NixOS-managed system trust store (_typically `/etc/ssl/certs/`_). After a `nixos-rebuild switch` with this entry active, all processes on the machine that use the system trust store — _browsers, curl, Penpot Desktop's embedded WebView_ — will accept TLS certificates signed by Caddy's local CA without warnings. This is what makes `https://design.penpot.local` present a trusted certificate rather than a browser security error.

The certificate lives at a path inside the Penpot project's persistent Docker volume:

```
/home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/APPS/Penpot/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/caddy/data/caddy/pki/authorities/local/root.crt
```

Caddy generates this certificate on first startup and stores it in its data volume. The volume is persistent — _Caddy does not regenerate the CA unless the volume is deleted or Caddy is explicitly reset._

**Bootstrap sequence** (_documented in source_): the Docker Compose stack must be started first (`docker compose up -d`) so Caddy generates its CA and writes `root.crt` to the volume path. Only then can `nixos-rebuild switch` be run to apply this config — _if the file does not exist at the path when NixOS evaluates this option, the build fails._ This ordering constraint is a manual operational dependency.

**Why is it here?** Caddy's auto-generated local CA is not in any upstream trust store — _it is unique to this machine and instance._ The only way to make the system trust it without clicking through browser warnings is to add it to the system PKI explicitly. `security.pki.certificateFiles` is the correct NixOS mechanism for this.

The source file includes a migration note: when a dedicated CypherOS local networking module is built, this entry (_and `networking.hosts`_) should migrate there to form a central registry of local service domains and trusted local CAs. This file is the reference implementation for that pattern.

```nix
security.pki.certificateFiles = [
  /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/APPS/Penpot/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/caddy/data/caddy/pki/authorities/local/root.crt
];
```

---

## Dependencies

**Imported files:**

- `./options.nix` — required; makes `cypher-os.apps.productivity.*` options available in NixOS evaluation context

**NixOS options set by this file:**

- `networking.hosts` — adds `design.penpot.local → 127.0.0.1`
- `security.pki.certificateFiles` — adds Caddy local CA root cert to system trust store

**nixpkgs packages required:**

- None

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Group kill-switch; must be `true` for this file to activate|
|`cypher-os.apps.productivity.penpot.enable`|`bool`|`false`|App kill-switch; activates DNS entry and CA trust|

---

## Comment Convention

Inline comments in source files use three header tiers to classify non-active code without explanation bloat. Deep rationale belongs here in the documentation, not in the source file.

```nix
# ── DEFERRED — not yet needed; low friction to add ───────────────────────────
# package-name  # reason: <one line>

# ── EXCLUDED — active decision not to include ────────────────────────────────
# package-name  # reason: BSL license / broken nixpkgs derivation / etc.

# ── PENDING — blocked on something external ──────────────────────────────────
# package-name  # blocked on: <what>
```

---

## Design Notes

- The `options.nix` direct import is not unique to this file — _it is the required pattern for every `*-system.nix` in CypherOS._ NixOS-context modules cannot see the HM `default.nix` import chain. Any `*-system.nix` that reads `cypher-os.*` options must import the relevant `options.nix` directly.
- The certificate path is hardcoded to an absolute path under `/home/cypher-whisperer/`. This is a deliberate pragmatic shortcut: the Penpot persistent data directory is fixed on this machine and the path is unlikely to change. It is acknowledged as a Known Limitation (_see below_).
- The migration path to a central CypherOS local networking setup is documented both in the source file's migration note and in ADR-004 of the Penpot project repository _(`docs/project/decisions/ADR-004-hosts-file-pending-resolved.md`_). The decision to leave it here until that  exists is intentional.
- The bootstrap sequence ordering constraint (_Caddy must run before `nixos-rebuild switch`_) is an operational dependency that cannot be expressed in Nix. It is documented in the source comment and must be followed manually when setting up a fresh machine or after the Caddy data volume is recreated.

---

## Known Limitations

- `security.pki.certificateFiles` path is hardcoded to `/home/cypher-whisperer/...`. This breaks on a different username or if the Penpot data directory is moved. No parametrisation exists yet — _this is a pragmatic shortcut for a single-user, single-machine setup._
- The bootstrap sequence is a manual operational dependency: the Penpot Docker Compose stack must be started and Caddy must have generated its CA before `nixos-rebuild switch` can succeed. If the certificate file does not exist at the declared path, the build fails. There is no guard or early error for this case.
- If Caddy's data volume is deleted and recreated (_e.g. during a Penpot instance reset_), Caddy generates a new CA with a new certificate. The path remains the same but the certificate content changes. `nixos-rebuild switch` must be run again after Caddy regenerates its CA to update the system trust store.
- Both `networking.hosts` and `security.pki.certificateFiles` are Penpot-specific concerns living in a general productivity module subtree. They are candidates for migration to a future CypherOS local networking module — _tracked in ADR-004 of the Penpot project._

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|HM counterpart|`./penpot-hm.nix`|
|Group HM defaults|`./hm.nix`|
|Penpot project ADR|`docs/project/decisions/ADR-004-hosts-file-pending-resolved.md` (Penpot project repo)|
|ADR (CypherOS)|_None yet — planned when local networking module is built_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/apps/productivity/penpot-system.nix
Context: NixOS system
Created: 2026-06-10
Updated: 2026-06-10
-->
