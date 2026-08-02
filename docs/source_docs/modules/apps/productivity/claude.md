<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Claude Desktop — `claude.nix`

> _Installs the Claude Desktop app from an external flake overlay and wires its MCP configuration file declaratively into the user's XDG config directory._

**Module path:** `modules/apps/productivity/claude.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-10`

---

## Responsibility

**Does:**

- Installs `pkgs.claude-desktop` into the user profile
- Sets `ELECTRON_OZONE_PLATFORM_HINT=auto` as a session environment variable for native Wayland rendering
- Writes `~/.config/Claude/claude_desktop_config.json` declaratively via `xdg.configFile`, making MCP server configuration version-controlled

**Does not:**

- Register the `pkgs.claude-desktop` package — _that is done by the system-level overlay in `hosts/nixos/configuration.nix`_
- Declare any `cypher-os.*` options — _those live in `options.nix`_
- Manage any MCP servers at present — _the `mcpServers` block is an empty placeholder awaiting a dedicated MCP configuration session_

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.productivity`|
|Imports `options.nix`|No — `options.nix` is imported by `default.nix`|
|Kill-switch guard|`lib.mkIf (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.claude.enable)`|
|Profile default|`lib.mkDefault true` set in `modules/apps/productivity/hm.nix`|

---

## Block Analysis

---

### Block 1 — Kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset, conditioned on both `productivity.enable` and `claude.enable` being `true`.

**What does it do?** When either is `false`, the block evaluates to `{}` — no package is installed, no session variable is set, and no config file is written. When both are `true`, the full config is passed to the HM evaluator.

**Why is it here?** Standard CypherOS two-level guard pattern — group switch AND app switch. Claude Desktop can be disabled independently of the rest of the productivity group without touching any other module.

```nix
config =
  lib.mkIf
    (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.claude.enable)
    { ... };
```

---

### Block 2 — `home.packages`

**What is this?** A single-item list passed to `home.packages`, referencing `pkgs.claude-desktop`.

**What does it do?** Installs the Claude Desktop binary into the user's Home Manager profile. `pkgs.claude-desktop` does not exist in nixpkgs — it is injected into the `pkgs` attrset by the system-level overlay registered in `hosts/nixos/configuration.nix`:

```nix
nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];
```

The `inputs.claude-desktop` flake input (`github:aaddrick/claude-desktop-debian`) is threaded into NixOS module evaluation via `specialArgs = { inherit inputs self; }` in `flake.nix`. Without the overlay being registered at the system level, `pkgs.claude-desktop` does not exist and this module fails at evaluation time with an "attribute not found" error.

**Why is it here?** Claude Desktop is not in nixpkgs. The overlay pattern is the correct mechanism for introducing a package from an external flake into `pkgs` without forking nixpkgs. The Home Manager module consumes the result of that system-level overlay — _it does not and should not re-register it._

```nix
home.packages = [ pkgs.claude-desktop ];
```

---

### Block 3 — `home.sessionVariables`

**What is this?** A `home.sessionVariables` attrset containing a single entry: `ELECTRON_OZONE_PLATFORM_HINT = "auto"`.

**What does it do?** Sets the environment variable in the user's session environment (written to `~/.profile` / shell init files by HM). At Claude Desktop launch time, Electron reads this variable and selects its display backend. The `auto` value instructs Chromium/Electron to detect the running compositor at runtime — if Wayland is available it uses the Wayland backend natively; if not, it falls back to XWayland. Hardcoding `"wayland"` would cause a crash on an X11 session; `"auto"` is the defensive choice.

**Why is it here?** Claude Desktop is an Electron app. On a GNOME Wayland session (the current CypherOS GNOME lens), Electron apps default to XWayland unless told otherwise — this produces blurry rendering on HiDPI and prevents native Wayland input handling. `ELECTRON_OZONE_PLATFORM_HINT=auto` is the standard fix applied to all Electron apps in CypherOS that run on Wayland.

```nix
home.sessionVariables = {
  ELECTRON_OZONE_PLATFORM_HINT = "auto";
};
```

---

### Block 4 — `xdg.configFile."Claude/claude_desktop_config.json"`

**What is this?** An `xdg.configFile` entry that writes a JSON file to `$XDG_CONFIG_HOME/Claude/claude_desktop_config.json`. The `text` field is produced by `builtins.toJSON`, converting a Nix attrset into a JSON string at evaluation time.

**What does it do?** Creates Claude Desktop's canonical MCP configuration file declaratively. Claude Desktop reads this file on launch to discover registered MCP servers. Currently the `mcpServers` attrset is empty — the file is written as `{"mcpServers":{}}`, which is a valid no-op config that tells Claude Desktop no MCP servers are registered. This is the intentional current state; MCP server configuration is a separate session concern.

The resolved path of this file depends on `XDG_CONFIG_HOME`. In the GNOME lens, the XDG profile launcher script (`modules/de/gnome/hm.nix`) sets `XDG_CONFIG_HOME=$HOME/.config/profiles/gnome` before starting `gnome-session`. As a result, Claude Desktop reads its config from `~/.config/profiles/gnome/Claude/claude_desktop_config.json` when launched in that session. This is intentional — each DE profile gets its own isolated XDG config namespace, meaning MCP server registrations can be DE-specific. This is a feature of the CypherOS per-DE XDG profile isolation architecture, not a bug.

**Why is it here?** Managing `claude_desktop_config.json` declaratively means MCP server registrations are version-controlled alongside the rest of CypherOS. Without this, MCP config would need to be set manually inside Claude Desktop's UI on every fresh activation. `builtins.toJSON` is used rather than a raw `text` string so the Nix attrset structure is type-safe and can be extended with additional keys without manual JSON formatting.

```nix
xdg.configFile."Claude/claude_desktop_config.json" = {
  text = builtins.toJSON {
    mcpServers = {
      # Placeholder — add MCP server entries here, e.g.:
      # filesystem = {
      #   command = "npx";
      #   args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/cypher-whisperer/Projects" ];
      # };
    };
  };
};
```

---

## Dependencies

**Imported files:**

- None directly

**Home Manager options set by this file:**

- `home.packages` — installs `pkgs.claude-desktop`
- `home.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT` — sets Electron Wayland hint
- `xdg.configFile."Claude/claude_desktop_config.json"` — writes MCP config

**nixpkgs packages required:**

- `pkgs.claude-desktop` — injected by the system-level overlay from `inputs.claude-desktop`; NOT in nixpkgs

**External flake inputs used:**

- `github:aaddrick/claude-desktop-debian` (as `inputs.claude-desktop`) — provides the `overlays.default` overlay that makes `pkgs.claude-desktop` available; registered in `hosts/nixos/configuration.nix`, not here

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Group kill-switch; must be `true` for this file to activate|
|`cypher-os.apps.productivity.claude.enable`|`bool`|`false`|App kill-switch; `lib.mkDefault true` set by `hm.nix`|

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

- The overlay registration and the HM package installation are intentionally split across two files: `configuration.nix` registers the overlay (NixOS context, system-wide), `claude.nix` installs the package (HM context, user profile). This split is necessary because overlays must be registered at the `nixpkgs` level which is a NixOS system concern — Home Manager modules cannot register nixpkgs overlays.
- `ELECTRON_OZONE_PLATFORM_HINT=auto` is set in `sessionVariables` rather than `shellAliases` or a wrapper script so it applies regardless of how Claude Desktop is launched — from a terminal, from GNOME Shell, or from a `.desktop` file.
- The `xdg.configFile` path (`"Claude/claude_desktop_config.json"`) is relative to `XDG_CONFIG_HOME`. Because CypherOS uses per-DE XDG profile isolation, this path resolves differently per DE — this is by design and enables per-DE MCP server registrations in the future.

---

## Known Limitations

- `mcpServers` is currently empty. Claude Desktop is installed and functional but has no MCP integrations configured. This is a PENDING item — a dedicated MCP configuration session is required to define and register servers.
- If the `claude-desktop` flake input (`github:aaddrick/claude-desktop-debian`) falls behind the official Claude Desktop release cadence, the installed version will be outdated. There is no automated update mechanism — a manual `nix flake update` is required to pull the latest version.
- The system-level overlay registration in `configuration.nix` is a hard prerequisite for this module. If it is missing or the flake input is unavailable, this module fails at evaluation time. There is no graceful fallback.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Group HM defaults|`./hm.nix`|
|Overlay registration|`hosts/nixos/configuration.nix`|
|Flake input|`github:aaddrick/claude-desktop-debian`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/apps/productivity/claude.nix
Context: Home Manager
Created: 2026-06-10
Updated: 2026-06-10
-->
