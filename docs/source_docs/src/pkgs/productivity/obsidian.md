<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Obsidian — `obsidian.nix`

> _Declarative Obsidian configuration: installs the app, manages vault `.obsidian/` config via Home Manager's `programs.obsidian` module, and wires community plugins as local Nix derivations built from compiled GitHub Release assets._

**Module path:** `modules/apps/productivity/obsidian.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-11`

---

## Responsibility

**Does:**

- Enables and configures `programs.obsidian` via Home Manager
- Builds each community plugin as a `stdenv.mkDerivation` that fetches compiled release assets (`main.js`, `manifest.json`, `styles.css`) from GitHub Releases via `fetchurl`, and passes the resulting derivations to `communityPlugins`
- Declares all active core plugins explicitly, including inline `settings` for `daily-notes`
- Declares appearance settings (_fonts, font sizes, editor behaviour_) in `defaultSettings.appearance` and `defaultSettings.app`
- Declares all keybindings in `defaultSettings.hotkeys`, mapping Obsidian command IDs to key chords
- Declares inline CSS snippets in `defaultSettings.cssSnippets`
- Registers a single vault at a `$HOME`-relative path; HM manages only `.obsidian/` inside it

**Does not:**

- Declare `cypher-os.*` options — _those live in `options.nix`_
- Manage workspace state (_`workspace.json`_) — _left unmanaged so Obsidian can persist live state (last open note, panel sizes, scroll positions) across sessions without being reset on every rebuild_
- Manage themes directly — _Catppuccin theming is delegated to `catppuccin/nix`, which injects the theme derivation into `programs.obsidian` automatically when `catppuccin.enable` is set globally and `programs.obsidian.enable = true`_
- Touch vault note content, `.git/`, `.trash/`, or any path outside `.obsidian/`

---

## Evaluation Context

| Property              | Value                                                                                                        |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| Evaluated by          | `homeManagerModules`                                                                                         |
| Options namespace     | `cypher-os.apps.productivity`                                                                                |
| Imports `options.nix` | No — _`options.nix` is imported by `default.nix` which also imports this file_                               |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.obsidian.enable)` |
| Profile default       | No `lib.mkDefault` set here — _toggled externally via `modules/profile/default.nix`_                         |

---

## Block Analysis

---

### Block 1 — `mkPlugin` helper

**What is this?** A `let`-bound function that accepts a structured attribute set and returns a `stdenv.mkDerivation`. It is not a module option — it is a local build helper used only within this file's `let` block.

**What does it do?** Fetches compiled release assets (`main.js`, `manifest.json`, and optionally `styles.css`) individually from the plugin's GitHub Releases page using `pkgs.fetchurl`, then copies them into the derivation output. The resulting store path is a directory containing exactly the files Obsidian expects to find in `.obsidian/plugins/<plugin-id>/`. The HM module then symlinks that store path into the vault at activation time. `stylesHash = null` skips `styles.css` for plugins that don't publish it.

**Why fetchurl over fetchFromGitHub?** Obsidian community plugins are Electron extensions loaded at runtime via Node's `require()`. The entry point is `main.js` — a compiled JavaScript bundle. This file is a build artifact: it is **not present in the plugin's git repository source tree**. `fetchFromGitHub` fetches the source tree at a given tag, which contains TypeScript source, a `package.json`, build config, etc., but no compiled `main.js`. A derivation built from source therefore has no `main.js`, and Obsidian throws "failed to load plugin" at startup despite the HM symlinks being correctly created. The compiled `main.js` is published exclusively to the GitHub Releases page for each version tag. Each file is fetched individually with `fetchurl` so that each has its own verified hash.

> **Incident note — 2026-06-10:** _This was the root cause of all six community plugins failing to load after the initial `nixos-rebuild boot` + reboot that activated this module. The HM activation completed without error, symlinks were correctly created, and `community-plugins.json` listed all plugins as enabled — but every plugin directory was missing `main.js`. Obsidian loaded the manifest, registered the plugin as enabled, then failed silently when it couldn't execute the missing entry point._

```nix

mkPlugin =
  {
    pname,
    version,
    owner,
    repo,
    mainJsHash,
    manifestHash,
    stylesHash ? null,
  }:
  pkgs.stdenv.mkDerivation {
    inherit pname version;
    dontUnpack = true;
    dontBuild = true;
    installPhase =
      let
        mainJs = pkgs.fetchurl {
          url = "https://github.com/${owner}/${repo}/releases/download/${version}/main.js";
          hash = mainJsHash;
        };
        manifest = pkgs.fetchurl {
          url = "https://github.com/${owner}/${repo}/releases/download/${version}/manifest.json";
          hash = manifestHash;
        };
      in
      ''
        mkdir -p $out
        cp ${mainJs}   $out/main.js
        cp ${manifest} $out/manifest.json
        ${lib.optionalString (stylesHash != null) ''
          cp ${pkgs.fetchurl {
            url = "https://github.com/${owner}/${repo}/releases/download/${version}/styles.css";
            hash = stylesHash;
          }} $out/styles.css
        ''}
      '';
  };
```
**Hash update workflow:** After bumping a plugin version, get new hashes with:

```bash
# Fetch and hash each release asset
nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/main.js
nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/manifest.json
nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/styles.css

# Convert raw base32 output to SRI format (required by hash = fields)
nix hash convert --hash-algo sha256 --to sri <raw-hash>
```

> Note: `nix hash to-sri` is deprecated as of current Nix versions. Use `nix hash convert --hash-algo sha256 --to sri` instead. The deprecated form still works but emits a warning.

> _Update accordingly, put them in a quick bash scripts and execute_


```bash
#!/bin/bash

# Style Settings 1.0.9
nix-prefetch-url https://github.com/mgmeyers/obsidian-style-settings/releases/download/1.0.9/main.js
nix-prefetch-url https://github.com/mgmeyers/obsidian-style-settings/releases/download/1.0.9/manifest.json
nix-prefetch-url https://github.com/mgmeyers/obsidian-style-settings/releases/download/1.0.9/styles.css

# Obsidian Git 2.32.1
nix-prefetch-url https://github.com/Vinzent03/obsidian-git/releases/download/2.32.1/main.js
nix-prefetch-url https://github.com/Vinzent03/obsidian-git/releases/download/2.32.1/manifest.json
nix-prefetch-url https://github.com/Vinzent03/obsidian-git/releases/download/2.32.1/styles.css

# Dataview 0.5.67
nix-prefetch-url https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.67/main.js
nix-prefetch-url https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.67/manifest.json
nix-prefetch-url https://github.com/blacksmithgu/obsidian-dataview/releases/download/0.5.67/styles.css

# Templater 2.9.0
nix-prefetch-url https://github.com/SilentVoid13/Templater/releases/download/2.9.0/main.js
nix-prefetch-url https://github.com/SilentVoid13/Templater/releases/download/2.9.0/manifest.json
nix-prefetch-url https://github.com/SilentVoid13/Templater/releases/download/2.9.0/styles.css

# Recent Files 1.7.4
nix-prefetch-url https://github.com/tgrosinger/recent-files-obsidian/releases/download/1.7.4/main.js
nix-prefetch-url https://github.com/tgrosinger/recent-files-obsidian/releases/download/1.7.4/manifest.json
# recent-files likely has no styles.css — check; if 404 skip it

# Calendar 1.5.10
nix-prefetch-url https://github.com/liamcain/obsidian-calendar-plugin/releases/download/1.5.10/main.js
nix-prefetch-url https://github.com/liamcain/obsidian-calendar-plugin/releases/download/1.5.10/manifest.json
nix-prefetch-url https://github.com/liamcain/obsidian-calendar-plugin/releases/download/1.5.10/styles.css

# Advanced Canvas
nix-prefetch-url https://github.com/Developer-Mike/obsidian-advanced-canvas/releases/download/6.2.0/main.js
nix-prefetch-url https://github.com/Developer-Mike/obsidian-advanced-canvas/releases/download/6.2.0/manifest.json
nix-prefetch-url https://github.com/Developer-Mike/obsidian-advanced-canvas/releases/download/6.2.0/styles.css

# optimized canvas connections
nix-prefetch-url https://github.com/felixchenier/obsidian-optimize-canvas-connections/releases/download/1.0.0/main.js
nix-prefetch-url https://github.com/felixchenier/obsidian-optimize-canvas-connections/releases/download/1.0.0/manifest.json

# Canvas Filter
nix-prefetch-url https://github.com/IKoshelev/Obsidian-Canvas-Filter/releases/download/0.9.4/main.js
nix-prefetch-url https://github.com/IKoshelev/Obsidian-Canvas-Filter/releases/download/0.9.4/manifest.json
nix-prefetch-url https://github.com/IKoshelev/Obsidian-Canvas-Filter/releases/download/0.9.4/styles.css
```


```bash

#!/bin/bash

for h in \
  0s3lap1hrrqqbby7qk5dxzw141dkhp2jb9h5nxw5ak5brnmana0q \
  1f5zwn3h32xf6r5d9mg38rj5g6qg9dlhn1g04143b89arwhdrzww \
  1n5zflq3c6i70p82h4vzbdym08rbazqfa2mkrj4klrahpv93fygf \
  05d97mdw47pn2n0v4xl86a6m7mkm1hc2sa0c2715fwny8irmdxsb \
  0pr479yvfd06k8clwbfhs4bqvys2djrbgsjsgiknjx878p7aiy4g \
  001kgmhcxg7d8mp0mf1m06vdlbh79xhq8sdqrlqqjgqn66x3pak1 \
  0sv35wx4il0vzwknfr89x0dih7jbfzh53jnm4sr3vrvykmph69k3 \
  07584jw89nxiaj40amz8rdfl8vsbhl5v5mx6d30srfgb8cyyfm9z \
  0v6433p8xb40ba54gf2vak5zd6xklihqa93xd86zfzahgayzzi6g \
  0fwj86x7f9jhxa6v63ldn8wpcvpac2kiibw922zh3hvk0gymn0ay \
  08ia7m6fhjcclqi91jxbiyfq49lysbs9w5lks5qc0nsg275wcny9 \
  1awr7mmxfs3av5496fj4px1ic2x0fajkgr510yk6crgs5hqlj38s \
  0nwjvkhlajhijwj3c47s00j3v5dxaqd87124kqa0r9wgmsb713j6 \
  0m7as25hm0kcj170khrhkxfvbz26njrcjfjp2lkimk7sy3k9kklx \
  09fi25vw52vjr35r7lgvfwvmnsrnbfw8lazs06lfbnwzrzlkkcvz \
  12yhwxxya70phsyvdggp31wkdzgpj224anrdl6x151b4709misgk
do
  echo "$h -> $(nix hash convert --hash-algo sha256 --to sri $h)"
done
```

---

### Block 2 — `mkTheme` helper (EXCLUDED)

**What is this?** A commented-out `let`-bound function, structurally identical to `mkPlugin`, that would have built the Catppuccin Obsidian theme as a local derivation. The install phase difference from `mkPlugin` is that it copies `obsidian.css` (the actual filename in the catppuccin/obsidian repo) and renames it to `theme.css` on output, because Obsidian requires that exact filename when loading a community theme.

**What does it do?** Nothing at present — it is excluded. When it was active it produced a derivation containing `manifest.json` + `theme.css`, which the HM module would symlink into `.obsidian/themes/Catppuccin/`.

**Why is it here?** The initial implementation managed the Catppuccin theme manually via this helper. During stabilisation it was discovered that `catppuccin/nix` — already present in CypherOS as the system-wide theming input — automatically injects the Catppuccin Obsidian theme derivation into `programs.obsidian.defaultSettings.themes` when `programs.obsidian.enable = true`. Having both sources active caused `findSingle` in the HM obsidian module to throw `"Only one theme can be enabled at a time."` because two entries in the `themes` list had `enable = true`. The resolution was to cede theme management entirely to `catppuccin/nix`. The helper and its associated `themeCatppuccin` derivation are kept as commented-out blocks rather than deleted so the build history and reasoning are visible without requiring a git blame lookup.

```nix
# mkTheme =
#   {
#     pname,
#     version,
#     owner,
#     repo,
#     rev ? version,
#     hash,
#   }:
#   pkgs.stdenv.mkDerivation {
#     inherit pname version;
#     src = pkgs.fetchFromGitHub {
#       inherit owner repo rev hash;
#     };
#     dontBuild = true;
#     installPhase = ''
#       mkdir -p $out
#       cp manifest.json $out/
#       [ -f obsidian.css ] && cp obsidian.css $out/theme.css
#     '';
#   };
```

---

### Block 3 — Plugin derivation bindings

**What is this?** Six `let`-bound attribute bindings — `pluginStyleSettings`, `pluginObsidianGit`, `pluginDataview`, `pluginTemplater`, `pluginRecentFiles`, `pluginCalendar` — each produced by calling `mkPlugin` with a specific plugin's release asset hashes.

**What does it do?** Each binding resolves to a store path (a derivation output directory) containing `main.js`, `manifest.json`, and `styles.css` where applicable. These bindings are referenced by name in the `communityPlugins` list — either as bare derivations or as the `pkg` field of a settings submodule. At `home-manager switch` time, HM symlinks each store path into the vault's `.obsidian/plugins/<plugin-id>/`.

**Why is it here?** Separating derivation construction from the `communityPlugins` list keeps the list readable — the list expresses _which plugins are active and with what settings_, while the `let` block expresses _how to build them_. All version and hash data is co-located, and the comment above the block documents the update workflow.

```nix

pluginStyleSettings = mkPlugin {
  pname        = "obsidian-style-settings";
  version      = "1.0.9";
  owner        = "mgmeyers";
  repo         = "obsidian-style-settings";
  mainJsHash   = "sha256-GCirqs2rTFV4twWmJcWFswUS+O+tTHz8WhjnDMNVdGg=";
  manifestHash = "sha256-nP/cIM8qoTVIIOAFC2lLD5tXZEbj1dRKNq6LAYflv7g=";
  stylesHash   = "sha256-7nk30r5QZTqJzLMK5fBXKyNQfVt/EyjQBScaNjB1v9g=";
};

pluginObsidianGit = mkPlugin {
  pname        = "obsidian-git";
  version      = "2.32.1";
  owner        = "Vinzent03";
  repo         = "obsidian-git";
  mainJsHash   = "sha256-S/dWc0TeclfCEQwoLRgMddZTjTKIdrKBFfYewls9qRU=";
  manifestHash = "sha256-j/iozkUHdWlnfFrqt7JsQvuNF9HQLU4ZmgY0t306JF8=";
  stylesHash   = "sha256-Yao7ujEWP4kxzbhphGFPBy7atgE1uApuRe28zmB9MwA=";
};

pluginDataview = mkPlugin {
  pname        = "dataview";
  version      = "0.5.67";
  owner        = "blacksmithgu";
  repo         = "obsidian-dataview";
  mainJsHash   = "sha256-YyYDb51+5z2yJtXKUeB3Sx4YG+gJZWcn/xvQSDovY2s=";
  manifestHash = "sha256-P1XnPUPruazBaKbXsguFS29EXcvoVwWIVLHbhLgkqBw=";
  stylesHash   = "sha256-z8T/vXpQffcNan0khWGks5v2y1RbuEeKWoCsju4YxGw=";
};

pluginTemplater = mkPlugin {
  pname        = "templater-obsidian";
  version      = "2.9.0";
  owner        = "SilentVoid13";
  repo         = "Templater";
  mainJsHash   = "sha256-XgFb/QNzwwG/EImvGKdg6m52ObKNDrON6lAmd7pBkjs=";
  manifestHash = "sha256-yVvGyxFPW8Bw0ZMWnvTSniaCnY+ry5AipoxJ6Ew9KiI=";
  stylesHash   = "sha256-Gg1JMSz6ZWamB6HkN6VyoAsWQ79EOpNI2Wpo12s9mas=";
};

pluginRecentFiles = mkPlugin {
  pname        = "recent-files-obsidian";
  version      = "1.7.4";
  owner        = "tgrosinger";
  repo         = "recent-files-obsidian";
  mainJsHash   = "sha256-Ro5wlq6PpwwUnkSEgxpWvZU9JAD6EDYklxFKReHckls=";
  manifestHash = "sha256-nc6Z5vD6zBonFVc6ybK0Rvy1XZ8wwwlOkGyCCovQ6lQ=";
  # no styles.css in this release
};

pluginCalendar = mkPlugin {
  pname        = "calendar";
  version      = "1.5.10";
  owner        = "liamcain";
  repo         = "obsidian-calendar-plugin";
  mainJsHash   = "sha256-f7M56c+f2+WoAforirhbNmtbN3f70ZPLyHKLwncR0SU=";
  manifestHash = "sha256-8+lYEzhkhRK6oS1bRYSQ9/02eRj3vba9hhcc5Xvn0Is=";
  # no styles.css in this release
};
```

---

### Block 4 — Kill-switch guard

**What is this?** A `lib.mkIf` expression wrapping the entire `config` attrset. It takes a boolean condition — the logical AND of two `cypher-os.*` option reads — and only produces the `config` output when both are `true`.

**What does it do?** When either `cypher-os.apps.productivity.enable` or `cypher-os.apps.productivity.obsidian.enable` is `false`, the entire block evaluates to `{}` — Home Manager sees no `programs.obsidian` configuration, Obsidian is not installed, and no vault files are symlinked. When both are `true`, the full `programs.obsidian` configuration is passed to the HM module for evaluation.

**Why is it here?** The two-condition guard reflects the module hierarchy: `productivity.enable` is the group-level kill-switch (disabling it disables all productivity apps), while `obsidian.enable` is the app-level kill-switch (allowing Obsidian to be toggled independently of e.g. Claude). This is the standard CypherOS guard pattern for leaf modules within a group.

```nix
config =
  lib.mkIf
    (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.obsidian.enable)
    { ... };
```

---

### Block 5 — `programs.obsidian` base

**What is this?** The top-level `programs.obsidian` attribute set, which is the entry point into the HM obsidian module. `enable = true` activates the module; `package = pkgs.obsidian` pins the package explicitly rather than accepting the module's default.

**What does it do?** `enable = true` causes HM to install the Obsidian package and activate all vault symlink management. Explicitly setting `package` means the Obsidian version is determined by the nixpkgs input pinned in the flake lock, not by whatever the HM module defaults to — this is intentional so that `nix flake update` is the single mechanism controlling the Obsidian version, same as every other package in CypherOS.

**Why is it here?** The explicit `package` pin is a defensive practice: HM module defaults can change between HM releases. Pinning it here makes the version source unambiguous.

```nix
programs.obsidian = {
  enable  = true;
  package = pkgs.obsidian;
  ...
};
```

---

### Block 6 — `defaultSettings.appearance`

**What is this?** An `attrsOf anything` attribute set passed to `defaultSettings.appearance`, which the HM module serialises into `appearance.json` inside every managed vault's `.obsidian/` directory.

**What does it do?** Sets three font family slots and base font size. Obsidian has three independent font slots — `interfaceFontFamily` (UI chrome: sidebars, menus), `textFontFamily` (editor and reading view body text), and `monospaceFontFamily` (inline code, code blocks). All three must be declared if any one is declared, otherwise unset slots reset to the system default font on each rebuild, producing inconsistent appearance depending on what the OS default happens to be. `baseFontSize` sets the global font size scalar; Obsidian's default is also 16, so this is declarative no-op that makes the value auditable.

The `cssTheme` key is commented out because `catppuccin/nix` derives and writes that value automatically from whichever theme in the `themes` list has `enable = true`. Writing it here as well would conflict. The `"theme"` key (dark/light mode override) is also commented out, left as a documented escape hatch for forcing dark mode explicitly if OS-level dark mode detection ever behaves unexpectedly.

**Why is it here?** Font choices are personal and not resettable — every `home-manager switch` would overwrite manually set fonts if they were not declared. Declaring them here makes the font state reproducible across rebuilds and machines.

```nix
appearance = {
  "interfaceFontFamily" = "Courier";
  "monospaceFontFamily" = "Courier";
  "textFontFamily"      = "Courier";
  "baseFontSize"        = 16;
};
```

---

### Block 7 — `defaultSettings.app`

**What is this?** An `attrsOf anything` attribute set serialised into `app.json` in the vault's `.obsidian/` directory. This controls Obsidian's editor behaviour, not its visual appearance.

The Home Manager Obsidian module defines `appSettingsType = with types; nullOr (attrsOf anything)` — _meaning `app` is a fully open attrset._ It accepts any key/value pair and serialises it directly to `app.json`. No escape hatch or `extraConfig` is needed; keys are added directly to the block and the module passes them through verbatim.

**What does it do?** Each key maps to an Obsidian editor, navigation, file management, or safety preference. The full key inventory:

| Key                        | Type              | Effect                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| -------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Editor Behavior**        |                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `readableLineLength`       | bool              | Constrains line width in reading/live-preview mode to a comfortable measure — _prevents full-width lines on wide monitors_                                                                                                                                                                                                                                                                                                                                   |
| `showLineNumber`           | bool              | Line numbers off — _keeps the editor surface clean; this is a notes app, not an IDE_                                                                                                                                                                                                                                                                                                                                                                         |
| `defaultViewMode`          | string            | Opens new notes in `live` (Live Preview) mode by default — _immediate rendered feedback without a split pane_                                                                                                                                                                                                                                                                                                                                                |
| `livePreview`              | bool              | Enables the hybrid source+preview editor engine; required for `defaultViewMode = "live"` to function                                                                                                                                                                                                                                                                                                                                                         |
| `tabSize`                  | bool              | Indentation width for nested lists and code blocks; 2 matches the broader CypherOS formatting convention                                                                                                                                                                                                                                                                                                                                                     |
| `useTab`                   | bool              | Uses spaces rather than hard tab characters — _consistent with `tabSize` above_                                                                                                                                                                                                                                                                                                                                                                              |
| `foldIndent`               | bool              | Enables folding of indented content blocks in the editor                                                                                                                                                                                                                                                                                                                                                                                                     |
| `foldHeading`              | bool              | Collapse headings on open. Useful for long ADRs, noisy in journals — _prevents context being hidden on open across a wide-concern vault_ `false`                                                                                                                                                                                                                                                                                                             |
| `showFrontmatter`          | bool              | Hides YAML frontmatter block in reading mode; still editable in source mode                                                                                                                                                                                                                                                                                                                                                                                  |
| `strictLineBreaks`         | bool              | `false` = Single newline renders as a line break _(GFM-compatible)_ — _keeps repo docs portable across external renderers_. Matters if docs render elsewhere. Keep `false` for repo markdown.                                                                                                                                                                                                                                                                |
| `spellcheck`               | bool              | Enables spell checking — _useful for journal, prose, and cross-domain vault entries_                                                                                                                                                                                                                                                                                                                                                                         |
| `spellcheckLanguages`      | list              | Spell check language list - _e.g. `["en"]`  **only relevant if `spellcheck = true`**. extend if the vault spans multiple written languages_                                                                                                                                                                                                                                                                                                                  |
| `smartIndentList`          | bool              | Auto-indents list item continuations on Enter — _prevents manual re-indenting in nested structures_                                                                                                                                                                                                                                                                                                                                                          |
| `autoConvertHtml`          | bool              | Converts pasted HTML to Markdown on paste — _reduces cleanup when pulling content from browsers_                                                                                                                                                                                                                                                                                                                                                             |
| **Navigation & Workspace** |                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `vimMode`                  | bool              | Vim keybindings off; preserved as a named toggle for deliberate future enabling                                                                                                                                                                                                                                                                                                                                                                              |
| `canvasSnap`               | bool              | snap cards to grid by default — cleaner spatial layout, especially for research boards where structure matters. Toggle off per canvas at runtime.                                                                                                                                                                                                                                                                                                            |
| `useMarkdownLinks`         | bool              | Writes standard Markdown links `[text](path)` instead of `[[wikilinks]]` if true — _critical for portability outside Obsidian_. wikilinks are Obsidian-only syntax and will break in GitHub/VSCode renders.                                                                                                                                                                                                                                                  |
| `newLinkFormat`            | string            | `"shortest"` / `"relative"` / `"absolute"`. **Use `"relative"` for repo docs**. Relative link paths — _keeps links valid in any renderer (GitHub, mdBook, VSCode preview)_                                                                                                                                                                                                                                                                                   |
| `alwaysUpdateLinks`        | bool              | Auto-updates internal links when a file is renamed — _`true` prevents silent broken references across the vault_                                                                                                                                                                                                                                                                                                                                             |
| `openNextToActiveLeaf`     | bool              | Opens new tabs adjacent to the active one instead of replacement — _preserves spatial context while navigating_                                                                                                                                                                                                                                                                                                                                              |
| `focusNewTab`              | bool              | Whether new tab steals focus on open — _direct navigation flow without manual click-to-focus_                                                                                                                                                                                                                                                                                                                                                                |
| `followSymlinks`           | bool              | Allows Obsidian to traverse symlinks into directories outside the vault root — _enables the repo-docs-as-vault-subfolder strategy_                                                                                                                                                                                                                                                                                                                           |
| `userIgnoreFilters`        | array _(strings)_ | List of directory name components that Obsidian excludes from both the file indexer and the inotify file watcher. <br><br>Matched as substring against each path component at vault traversal time during startup.<br><br>Directories matching any entry are neither indexed nor watched — _preventing EACCES crashes when symlinked repositories contain read-only files (e.g. `.git/objects/pack`) and suppressing noise from build artifact directories._ |
| **Files & Attachments**    |                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `attachmentFolderPath`     | string            | Where dropped/pasted attachments land relative to the current note — _keeps repo directories clean_. (Set per-vault to keep repos clean, e.g. `"./assets"`.)                                                                                                                                                                                                                                                                                                 |
| `newFileLocation`          | string            | New notes are created in the same folder as the currently active note — _contextually appropriate across a multi-concern vault_ (`"root"` / `"current"` / `"folder"`. Use `"current"` so new files land relative to what you're editing.)                                                                                                                                                                                                                    |
| `newFileLocation`          | string            | `"root"` / `"current"` / `"folder"`. Use `"current"` so new files land relative to what you're editing.                                                                                                                                                                                                                                                                                                                                                      |
| **Performance/Behavior**   |                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `promptDelete`             | bool              | Confirms before deleting — _essential guard when editing files that are symlinked into live repos_. `false` = instant delete, risky on symlinked repo files. Keep `true`.                                                                                                                                                                                                                                                                                    |
| `trashOption`              | string            | Sends deleted files to the system trash — _recoverable and keeps the vault directory clean_ (`"local"` (`.trash/` folder in vault) / `"system"` / `"none"`. Use `"system"` — cleaner for repos.)                                                                                                                                                                                                                                                             |
| `pdfExportSettings`        | object            |                                                                                                                                                                                                                                                                                                                                                                                                                                                              |

**Why is it here?** Without this block, Obsidian's defaults apply — _notably `defaultViewMode` would be `preview`, `readableLineLength` would be `false`, and `useMarkdownLinks` would be `false` (wikilinks)._ Declaring all keys explicitly means every fresh vault activation or new machine starts with a consistent, intentional, fully-documented editor state. The exhaustive declaration is deliberate: on a glance read of the source file, configuration and intention are both immediately legible.

```nix
app = {
  # ── Reading & editor behaviour ─────────────────────────────────────────────

  # Constrains line width in reading/source view — reduces eye-tracking fatigue on wide monitors.
  "readableLineLength" = true;

  # Hides line numbers — cleaner prose environment; re-enable if you ever do heavy structural editing.
  "showLineNumber" = false;

  # Opens files in Live Preview by default — immediate rendered feedback without a split pane.
  "defaultViewMode" = "live";

  # Enables the hybrid source+preview editor engine; required for defaultViewMode = "live".
  "livePreview" = true;

  # Indentation width — aligns with your repo and devenv tab conventions.
  "tabSize" = 2;

  # Uses spaces rather than hard tab characters — consistent with tabSize above.
  "useTab" = false;

  # Collapses indented list items — useful in long structured notes; toggle per note as needed.
  "foldIndent" = true;

  # Collapses headings on open — disabled; auto-hiding context on open is disorienting in a wide-concern vault.
  "foldHeading" = false;

  # Hides YAML frontmatter block in reading mode — cleaner output for prose-heavy notes.
  "showFrontmatter" = false;

  # Single newline renders as a line break (GFM-compatible) — keeps repo docs portable across renderers.
  "strictLineBreaks" = false;

  # Enables spell checking — useful for journal and prose entries across all vault concerns.
  "spellcheck" = true;

  # Spell check language set — extend if your vault spans multiple written languages.
  "spellcheckLanguages" = [ "en" ];

  # Auto-indents continuation of list items on Enter — prevents manual re-indenting in nested lists.
  "smartIndentList" = true;

  # Converts pasted HTML to Markdown on paste — reduces cleanup when pulling content from browsers.
  "autoConvertHtml" = true;

  # Vim keybindings — disabled; toggle if modal editing ever becomes preferable.
  "vimMode" = false;
  
  # Canvas: snap cards to grid by default — cleaner spatial layout, especially 
  # for research boards where structure matters. Toggle off per canvas at runtime. 
  "canvasSnap" = true;

  # ── Links & navigation ──────────────────────────────────────────────────────

  # Writes standard Markdown links instead of [[wikilinks]] — critical for portability outside Obsidian.
  "useMarkdownLinks" = true;

  # Relative link paths — keeps links valid in any renderer (GitHub, mdBook, VSCode preview).
  "newLinkFormat" = "relative";

  # Auto-updates links when a file is renamed — prevents silent broken references across the vault.
  "alwaysUpdateLinks" = true;

  # Opens new tabs adjacent to the active one — preserves spatial context while navigating.
  "openNextToActiveLeaf" = true;

  # New tab steals focus on open — direct navigation flow without manual click-to-focus.
  "focusNewTab" = true;

  # Allows Obsidian to traverse symlinks into directories outside the vault root.
  "followSymlinks" = true;
  
  "userIgnoreFilters" = [
    # ── Version control ──────────────────────────────────────────────────────
    ".git" # Git internals — pack objects are 444 read-only; EACCES root cause

    # ── Node / JavaScript / TypeScript ───────────────────────────────────────
    "node_modules" # npm/yarn/pnpm deps — can contain thousands of .md files
    ".yarn" # Yarn PnP cache and install state
    "bower_components" # Legacy Bower packages (unlikely but defensive)
    ".nyc_output" # nyc/Istanbul coverage raw data
    ".sass-cache" # node-sass compilation cache
    "dist" # Compiled/bundled output (TS, Vite, webpack, etc.)
    "build" # Generic build output dir
    ".next" # Next.js build cache and output
    ".nuxt" # Nuxt build cache
    ".svelte-kit" # SvelteKit build output
    ".turbo" # Turborepo cache
    ".parcel-cache" # Parcel bundler cache
    ".cache" # Generic cache dir (Babel, Gatsby, etc.)
    "coverage" # Jest/Vitest/Istanbul HTML coverage reports

    # ── PHP / Composer ───────────────────────────────────────────────────────
    "vendor" # Composer packages — can be enormous

    # ── Python ───────────────────────────────────────────────────────────────
    "__pycache__" # Compiled bytecode (.pyc files)
    ".venv" # Python virtualenv (common convention)
    "venv" # Python virtualenv (alternate convention)
    ".pytest_cache" # pytest run cache
    ".mypy_cache" # mypy type-checker cache
    ".ruff_cache" # ruff linter cache

    # ── Rust ─────────────────────────────────────────────────────────────────
    "target" # Cargo build artifacts — can be gigabytes; contains binaries

    # ── Go ───────────────────────────────────────────────────────────────────
    # Go outputs to named binaries; no standard ignored dir beyond build/

    # ── Java / JVM ───────────────────────────────────────────────────────────
    ".gradle" # Gradle build cache and wrapper
    ".m2" # Maven local repository cache

    # ── Nix / NixOS ──────────────────────────────────────────────────────────
    "result" # nix build symlink output — points into /nix/store (read-only)
    ".devenv" # devenv state dir — contains symlinks into Nix store + DB files
    ".direnv" # direnv cache — nix-direnv writes shell env here

    # ── Docker / Containers ──────────────────────────────────────────────────
    ".docker" # Docker context and config fragments

    # ── IDEs and editors ─────────────────────────────────────────────────────
    ".idea" # JetBrains IDE project files
    ".vscode" # VS Code workspace settings (unlikely in vault but defensive)

    # ── OS and system ────────────────────────────────────────────────────────
    ".DS_Store" # macOS metadata (irrelevant on NixOS but harmless to list)
    "Thumbs.db" # Windows thumbnail cache

    # ── Logs ─────────────────────────────────────────────────────────────────
    ".log" # Log output directories named .log (tsserver, etc.)
  ];

  # ── Files & attachments ─────────────────────────────────────────────────────

  # Dropped/pasted attachments land in ./assets relative to the current note — keeps repos clean.
  "attachmentFolderPath" = "./assets";

  # New notes are created in the same folder as the currently active note — contextually appropriate.
  "newFileLocation" = "current";

  # ── Safety ──────────────────────────────────────────────────────────────────

  # Confirms before deleting — essential guard when editing files that are symlinked into live repos.
  "promptDelete" = true;

  # Sends deleted files to the system trash — recoverable and keeps the vault directory clean.
  "trashOption" = "system";
};
```
---

### Block 8 — `defaultSettings.corePlugins`

**What is this?** A list passed to `defaultSettings.corePlugins`. The HM module's type for this option is `listOf (coercedTo (enum corePluginsList) (p: { name = p; }) (submodule corePluginsOptions))` — meaning each entry is either a bare string (auto-coerced to `{ name = p; enable = true; settings = null; }`) or an explicit submodule with `name`, `enable`, and `settings` fields.

**What does it do?** This list is serialised into `core-plugins.json`, which is Obsidian's record of which built-in plugins are active. The HM module unconditionally overwrites this file on every activation — any plugin not listed here will be disabled, regardless of what was previously set manually. The full set of known core plugin IDs is enumerated in the HM module source, and only IDs from that enum are accepted.

The `daily-notes` entry is the only one expanded to the submodule form because it carries `settings`. Those settings are serialised into `daily-notes.json` _(the plugin's own config file)_, configuring where new daily notes are created, what filename format they use, whether a template is applied, and whether the plugin auto-opens today's note on launch. Every other plugin is a bare string — `enable = true` and `settings = null` by default.

Commented-out entries (`footnotes`, `publish`, `random-note`, `sync`) are plugins that exist in Obsidian's core set but are not relevant to this workflow. They are listed and commented rather than omitted so the full known set is auditable in one place and re-enabling one is a one-character change.

A few Notes:
1. **`bases`**:
    - this is Obsidian's new structured data/database feature _(landed in v1.8)_. 
    - Think Notion-style tables backed by your markdown frontmatter, queryable like Dataview but native.
    - It's relevant because there's already a community plugin that renders Bases content **on Canvas** — _you can have a live database view as a node on your spatial board._
      
2. **`webviewer`**:
    - required if you want Canvas webpage cards _(the fully interactive iframe nodes)_ to actually work.
    - Without this enabled, URL-type canvas nodes render a broken empty frame.
      
3. **`properties`**:
    - surfaces YAML frontmatter as a visual property panel.
    - Once you start using Canvas heavily for research, tagging notes with frontmatter _(`status`, `topic`, `source`, etc.)_ and querying them via Dataview or Bases becomes a necessity.

**Why is it here?** Because the HM module overwrites `core-plugins.json` unconditionally, omission equals disablement. An explicit, auditable list is the only safe approach — it prevents silent plugin disablement on rebuild caused by a forgotten entry.

```nix
corePlugins = [
  # ── Navigation & UI ─────────────────────────────────────────────────────────
  "file-explorer" # left-panel file tree
  "global-search" # vault-wide full-text search
  "switcher" # Ctrl+O (quick open palette) quick note switcher
  "command-palette" # Ctrl+P quick command launcher
  "bookmarks" # persisitent notes, headings, searches to sidebar
  "outline" # heading tree of current note (ease of in-note navigation)
  "page-preview" # hover popover preview on internal links
  "backlink" # shows which notes link to the current note
  "outgoing-link" # panel showing links from current note
  "tag-pane" # tag browser (sidebar listing all tags)
  "word-count" # document word count in status bar

  # ── Editing ─────────────────────────────────────────────────────────────────
  "editor-status" # cursor position in status bar
  "templates" # basic templating (use Templater plugin for power use)
  "note-composer" # merge/split/extract note operations.
  "slash-command" # / trigger for commands inline

  # ── Knowledge graph & canvas ────────────────────────────────────────────────
  "graph" # knowledge graph visualisation (local + global)
  "canvas" # infinite spatial canvas.

  # ── Daily workflow ──────────────────────────────────────────────────────────
  "file-recovery" # snapshot-based file recovery — always keep this on.

  # one-note-per-day journaling / scratchpad
  # Each entry in defaultSettings.corePlugins accepts a settings field of type
  # nullOr (attrsOf anything) — core plugin settings are declared inline on the
  # plugin entry itsel.
  {
    name = "daily-notes";
    settings = {
      "folder" = "THE_CHAMBER_OF_SECRETS/00_MASTER_JOURNAL/DAILY_NOTES";
      "format" = "YYYY_MM_DD";
      "template" = ""; # path to a template note if you want one; empty = none for now
      "autorun" = false; # true = opens today's note automatically on Obsidian launch
    };
  }

  # ── Data & structure ────────────────────────────────────────────────────────
  "bases" # Obsidian's native database/property system (new in 1.8)
  "properties" # (frontmatter properties panel) surfaces YAML frontmatter as visual property panel.
  "webviewer" # built-in browser pane — needed for webpage cards on canvas

  # ──────────────────────────────────────────────────────────────────────────────
  "audio-recorder" # record audio notes from within Obsidian
  "markdown-importer"
  "slides" # presentation mode for notes
  "workspaces"
  "zk-prefixer"

  # "footnotes"
  # "publish"
  # "random-note"
  # "sync"
];
```

---

### Block 9 — `defaultSettings.communityPlugins`

**What is this?** A list passed to `defaultSettings.communityPlugins`. The HM module type is `listOf (coercedTo package (p: { pkg = p; }) (submodule communityPluginsOptions))` — each entry is either a bare derivation (auto-coerced to `{ pkg = drv; enable = true; settings = null; }`) or an explicit submodule carrying `pkg`, `enable`, and `settings`.

**What does it do?** At activation, the HM module symlinks each plugin derivation's output path into `.obsidian/plugins/<plugin-id>/`, writes the list of active plugin IDs to `community-plugins.json`, and — for entries with non-null `settings` — writes the settings attrset as JSON to `.obsidian/plugins/<plugin-id>/data.json`. Because these are symlinks from the Nix store, Obsidian cannot write back to `data.json` at runtime for managed plugins. Any plugin setting you want to persist must be declared in the `settings` block here.

Plugin-by-plugin summary:

- **Style Settings** (`pluginStyleSettings`) — mandatory companion to the Catppuccin theme. Without it, the Catppuccin Preferences → Appearance panel is empty and the theme renders with its default palette only (Mocha, no accent customisation). The `settings` block sets flavor to `mocha` and accent to `mauve`. The exact key names (`catppuccin@@flavor`, `catppuccin@@accent`) are Style Settings' CSS variable addressing scheme.

- **Obsidian Git** (`pluginObsidianGit`) — auto-commits and pushes the vault to its git remote on a timer. `autoSaveInterval = 10` commits every 10 minutes; `autoPushInterval = 0` means push on every commit. `commitMessage` uses Obsidian Git's `{{date}}` template token.

- **Dataview** (`pluginDataview`) — enables SQL-like queries over vault frontmatter. `enableDataviewJs = true` unlocks the `dataviewjs` code block type for JavaScript-powered queries. Inline DataviewJS (`enableInlineDataviewJs`) is off by default — it's a more aggressive feature and not needed until explicitly used. Date formats are set to match the vault's `YYYY_MM_DD` convention.

- **Templater** (`pluginTemplater`) — replaces the built-in Templates core plugin for any non-trivial templating need. `auto_jump_to_cursor = true` means after a template is inserted, the cursor moves to the first `<% tp.file.cursor() %>` marker automatically. `templates_folder` points to the vault-relative path where Templater looks for template files.

- **Recent Files** (`pluginRecentFiles`) — bare derivation, no settings. Adds a sidebar panel listing recently opened notes. Zero configuration surface.

- **Calendar** (`pluginCalendar`) — bare derivation, no settings. Renders a month-view calendar in the right sidebar; each day cell links to that day's Daily Note. Its value depends entirely on Daily Notes usage — it is a navigator, not a note-taker.


**Why is it here?** Community plugins have no system-level install mechanism — they must be in `.obsidian/plugins/` to be loaded. This block is the complete, auditable manifest of all active community plugins. Adding a plugin without declaring it here means it will not exist in the vault on the next rebuild.

The only watch-out: the upstream module merges `app.json` and `appearance.json` but `community-plugins.json` is **replaced, not merged**, per vault. If you ever want vault-specific plugin subsets, you'll need to explicitly redeclare the full list at the vault level. For your current single-vault setup this doesn't matter yet.

```nix
communityPlugins = [
  {
    pkg = pluginStyleSettings;
    settings = {
      "catppuccin@@flavor" = "mocha";
      "catppuccin@@accent" = "mauve";
    };
  }
  {
    pkg = pluginObsidianGit;
    settings = {
      "autoSaveInterval" = 10;
      "autoPushInterval" = 0;
      "commitMessage"    = "vault: auto-commit {{date}}";
      "disablePopups"    = false;
      "showStatusBar"    = true;
    };
  }
  {
    pkg = pluginDataview;
    settings = {
      "enableDataviewJs"       = true;
      "enableInlineDataviewJs" = false;
      "warnOnEmptyResult"      = false;
      "defaultDateFormat"      = "dd/MM/yyyy";
      "defaultDateTimeFormat"  = "HH:mm - dd/MM/yyyy";
    };
  }
  {
    pkg = pluginTemplater;
    settings = {
      "trigger_on_file_creation" = false;
      "auto_jump_to_cursor"      = true;
      "templates_folder"         = "TEMPLATES";
    };
  }
  
  pluginRecentFiles
  pluginCalendar
  pluginAdvancedCanvas
  pluginOptimizeCanvasConnections
  pluginCanvasFilter
];
```

---

### Block 10 — `defaultSettings.cssSnippets`

**What is this?** A list passed to `defaultSettings.cssSnippets`. Each entry is either a file path (coerced to `{ source = path; }`) or a submodule with `name`, `source`, and `text` fields. Text entries are written as inline CSS files; source entries copy an external `.css` file.

**What does it do?** The HM module writes each snippet into `.obsidian/snippets/<name>.css` and records which snippets are enabled in `appearance.json`. The single active snippet (`stop-blinking-cursor`) injects a one-rule override that removes the CodeMirror cursor blink animation via `animation: none !important`.

**Why is it here?** The blinking cursor is a visual distraction in an environment intended for focused writing and reading. This is a minimal, self-contained CSS override that does not depend on any theme or plugin. Declaring it here rather than managing it manually ensures it survives theme changes and vault resets.

```nix
cssSnippets = [
  {
    name = "stop-blinking-cursor";
    text = ''
      /* Disable blinking cursor in editor */
      .cm-cursorLayer { animation: none !important; }
    '';
  }
];
```

---

### Block 11 — `defaultSettings.hotkeys`

**What is this?** An `attrsOf (listOf (attrsOf anything))` attribute set serialised into `hotkeys.json`. Keys are Obsidian command IDs in the format `"<plugin-id>:<command-id>"`. Values are lists of binding objects, each with a `modifiers` list and a `key` string. An empty list `[]` removes the default binding for that command without assigning a new one.

**What does it do?** Establishes a keyboard-first workflow where every frequently used action has a direct chord, removing the need to reach for the mouse or navigate the command palette for routine operations. The bindings are organised into logical groups:

|Group|Commands|
|---|---|
|Navigation|`command-palette:open`, `switcher:open`, `app:go-back`, `app:go-forward`, `bookmarks:open`|
|Editor line ops|`editor:swap-line-down`, `editor:swap-line-up`, `editor:toggle-bold`, `editor:toggle-italics`|
|Sidebar toggles|`app:toggle-left-sidebar` (`Ctrl+[`), `app:toggle-right-sidebar` (`Ctrl+]`)|
|Insert primitives|`editor:insert-code-block` (`Ctrl+Shift+K`), `table-editor-obsidian:insert-table` (`Ctrl+Shift+T`)|
|Tab management|new, close, next, previous, split vertical, split horizontal|
|Graph|global graph (`Ctrl+Shift+G`), local graph (`Ctrl+Alt+G`)|
|Daily note|`daily-notes:goto-today` (`Ctrl+T`) — single-keystroke jump to today's entry point|
|Folding|fold all, unfold all, toggle fold on current heading|
|Mode toggle|`markdown:toggle-preview` (`Ctrl+E`) — switch between source and reading view|

`app:open-help` is explicitly bound to `[]` to remove the default `F1` binding, which conflicts with terminal muscle memory.

**Why is it here?** Keybindings declared here are reproducible — manual bindings set inside Obsidian are part of `hotkeys.json`, which HM manages. Without declarative bindings, every fresh activation would reset to Obsidian defaults. The binding set is designed for progressive adoption: it mirrors conventions from other tools already in the workflow (Vim-adjacent fold keys, browser-style tab management) to reduce the cognitive cost of building muscle memory.

```nix
hotkeys = {
  "command-palette:open"              = [{ modifiers = [ "Ctrl" ];         key = "P"; }];
  "app:open-help"                     = [];
  "switcher:open"                     = [{ modifiers = [ "Ctrl" ];         key = "O"; }];
  "editor:swap-line-down"             = [{ modifiers = [ "Alt" ];          key = "ArrowDown"; }];
  "editor:swap-line-up"               = [{ modifiers = [ "Alt" ];          key = "ArrowUp"; }];
  "editor:toggle-bold"                = [{ modifiers = [ "Ctrl" ];         key = "B"; }];
  "editor:toggle-italics"             = [{ modifiers = [ "Ctrl" ];         key = "I"; }];
  "app:toggle-left-sidebar"           = [{ modifiers = [ "Ctrl" ];         key = "["; }];
  "app:toggle-right-sidebar"          = [{ modifiers = [ "Ctrl" ];         key = "]"; }];
  "table-editor-obsidian:insert-table"= [{ modifiers = [ "Ctrl" "Shift" ]; key = "T"; }];
  "editor:insert-code-block"          = [{ modifiers = [ "Ctrl" "Shift" ]; key = "K"; }];
  "workspace:new-tab"                 = [{ modifiers = [ "Ctrl" ];         key = "N"; }];
  "workspace:close-tab"               = [{ modifiers = [ "Ctrl" ];         key = "W"; }];
  "workspace:next-tab"                = [{ modifiers = [ "Ctrl" "Alt" ];         key = "ArrowRight"; }];
  "workspace:previous-tab"            = [{ modifiers = [ "Ctrl" "Alt" ]; key = "ArrowLeft"; }];
  "workspace:split-vertical"          = [{ modifiers = [ "Ctrl" "Shift" ]; key = "\\"; }];
  "workspace:split-horizontal"        = [{ modifiers = [ "Ctrl" "Shift" ]; key = "-"; }];
  "app:go-back"                       = [{ modifiers = [ "Ctrl" "Alt" ];         key = "H"; }];
  "app:go-forward"                    = [{ modifiers = [ "Ctrl" "Alt" ];         key = "L"; }];
  "bookmarks:open"                    = [{ modifiers = [ "Ctrl" "Shift" ]; key = "B"; }];
  "graph:open"                        = [{ modifiers = [ "Ctrl" "Shift" ]; key = "G"; }];
  "graph:open-local"                  = [{ modifiers = [ "Ctrl" "Alt" ];   key = "G"; }];
  "daily-notes:goto-today"            = [{ modifiers = [ "Ctrl" ];         key = "T"; }];
  "editor:fold-all"                   = [{ modifiers = [ "Ctrl" "Shift" ]; key = "."; }];
  "editor:unfold-all"                 = [{ modifiers = [ "Ctrl" "Shift" ]; key = ","; }];
  "editor:toggle-fold"                = [{ modifiers = [ "Ctrl" ];         key = "."; }];
  "markdown:toggle-preview"           = [{ modifiers = [ "Ctrl" ];         key = "E"; }];
  
  # ── Canvas ───────────────────────────────────────────────────────────    
  # create new canvas 
  "canvas:new-file" = [ { modifiers = [ "Ctrl" "Shift" ]; key = "C"; } ]; 
  # export canvas to PNG/SVG 
  "canvas:export-as-image" = [ { modifiers = [ "Ctrl" "Shift" ]; key = "E"; } ];
  
  # canvas:convert-to-file has no default — assign if you use inline text cards heavily 
  # canvas:zoom-to-fit — already defaults to Shift+1 on most systems; override if needed
};
```

---

### Block 12 — `vaults`

**What is this?** An `attrsOf` submodule passed to `programs.obsidian.vaults`. Each attribute key is an arbitrary Nix identifier; the meaningful field is `target`, a `$HOME`-relative path string that tells HM where the vault root is.

**What does it do?** HM uses `target` to locate the vault directory and write symlinks under `<target>/.obsidian/`. The Nix attribute key (`my-obsidian-notes`) is internal to HM's evaluation — it does not appear on disk anywhere. Only one vault is declared. Vault-specific `settings.*` overrides are available (commented out as examples) for cases where this vault needs to diverge from `defaultSettings` — for example, switching to a different theme or a different core plugin set.

**Why is it here?** The vault declaration is what connects all the `defaultSettings` configuration to a physical location on disk. Without it, `defaultSettings` is evaluated but nothing is written anywhere. The vault path is deeply nested under `DATA/FILES/PROJECTS/PRIVATE/PERSONAL/` to match the broader CypherOS data directory convention.

```nix
vaults = {
  my-obsidian-notes = {
    target = "DATA/FILES/PROJECTS/PRIVATE/PERSONAL/MY_OBSIDIAN_NOTES";
  };
};
```

---

## Dependencies

**Imported files:**

- None directly — `options.nix` and this file are both imported by `default.nix`, making `cypher-os.*` options available at evaluation time without a local import.

**Home Manager options set by this file:**

- `programs.obsidian.*` — the full `programs.obsidian` subtree as documented in Block Analysis above

**nixpkgs packages required:**

- `pkgs.obsidian` — the Obsidian desktop app
- `pkgs.stdenv.mkDerivation` — used by `mkPlugin` to build each community plugin
- `pkgs.fetchurl` — fetches individual release assets; requires network access during build

**External flake inputs used:**

- `catppuccin/nix` — injects the Catppuccin theme derivation into `programs.obsidian.defaultSettings.themes` automatically; this file does not reference it directly but depends on it being present in the HM module imports

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Group-level kill-switch; `false` disables all productivity modules including this one|
|`cypher-os.apps.productivity.obsidian.enable`|`bool`|`false`|App-level kill-switch; enables `programs.obsidian` and all vault symlink management|

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

- `mkPlugin` fetches compiled release assets from GitHub Releases using `fetchurl` — not source trees via `fetchFromGitHub`. The source tree does not contain `main.js`.

- Theme management is EXCLUDED from this file. `catppuccin/nix` owns it. The commented-out `mkTheme` and `themeCatppuccin` blocks are retained as build history — they document the failed approach (manual theme fetch conflicting with catppuccin/nix's implicit injection) and its resolution without requiring a git blame.

- `workspace.json` is intentionally unmanaged. Because HM symlinks config files from the Nix store, Obsidian cannot write back to managed files at runtime. Managing `workspace.json` would reset Obsidian's live state (last open note, panel positions, scroll offsets) on every rebuild. The tradeoff — non-reproducible workspace state in exchange for usable session persistence — is the correct one for a daily-driver notes application.

- The `communityPlugins` type uses `coercedTo package` which means a bare derivation like `pluginRecentFiles` is valid and auto-wraps to `{ pkg = drv; enable = true; settings = null; }`. Plugins needing `settings` must use the explicit submodule form. Mixing both forms in the same list is intentional and correct.

- `programs.obsidian.defaultSettings.app{};`
	-  `defaultViewMode` set to `"live"`, not `"source"`
		- The original configuration had `"defaultViewMode" = "source"` alongside `"livePreview" = true`.
		- These two keys are not independent: `defaultViewMode` governs which editor mode files open in, and `livePreview` enables the Live Preview engine within that mode.
		- Setting `defaultViewMode = "source"` with `livePreview = true` does not produce a live-preview-on-open experience — _it opens files in raw source mode and makes Live Preview available as a toggle._
		- Since the motivation for using Obsidian over VSCode is immediate rendered feedback, `"live"` is the coherent value. Both keys are retained to make the dependency explicit.

	-  `useMarkdownLinks` and `newLinkFormat` as a mandatory pair
		- These two keys must be set together.
		- `useMarkdownLinks = true` switches Obsidian's link insertion from `[[wikilink]]` syntax to standard Markdown `[text](path)`.
		- `newLinkFormat = "relative"` then controls the path format of those Markdown links.
		- Without `newLinkFormat`, Obsidian defaults to shortest-match paths, which can produce ambiguous or vault-root-relative paths that break outside Obsidian.
		- Together, the pair locks all generated links to portable, renderer-agnostic relative paths — _correct in GitHub, VSCode preview, mdBook, and any static site generator._

	-  Exhaustive explicit declaration as an intentional convention
		- All keys are declared including those whose values match Obsidian's own defaults.
		- This is deliberate: the source file is the single source of truth for the editor state.
		- An omitted key is ambiguous — _it could mean "default is acceptable" or "this was never considered."_
		- An explicit declaration with a comment removes that ambiguity entirely.
		- The cost is verbosity; the benefit is that the file is self-documenting and audit-ready on a single read-through.

    - Symlinked repositories use root-level symlinks with watcher exclusions, not subdirectory symlinks.
        - When integrating external repository documentation into the vault via symlinks, _AND_ the symlink targets the repository root rather than individual _(NESTED)_ subdirectories, there is a mitigation strategy against EACCESS error.
          
        - This preserves the self-contained module documentation convention _(source files and their `docs/` co-located within module group directories)_ and avoids maintaining one symlink per module group as the repository grows. 
        - The tradeoff — that non-documentation directories _(`.git/`, build artifacts, Nix store symlinks)_ are also reachable — is mitigated entirely by `userIgnoreFilters`. `followSymlinks = true` enables traversal; `userIgnoreFilters` constrains what is actually watched and indexed. See `INC_2026_06_12_001`.

---

## Known Limitations

- Style Settings `data.json` key names (`catppuccin@@flavor`, `catppuccin@@accent`) were derived from the plugin's CSS variable addressing scheme and community documentation — they have not been verified by inspecting a live `data.json` after manual configuration. If Catppuccin flavor/accent controls don't appear in Preferences after activation, inspect `.obsidian/plugins/obsidian-style-settings/data.json` in a manually-configured vault to derive the exact key names and update `settings` accordingly.
- `workspace.json` is unmanaged — _workspace layout is not reproducible across machines or fresh activations._
- Plugin hashes must be manually updated after `nix flake update` if nixpkgs bumps a plugin's pinned revision. There is no automated hash-update mechanism.
- `daily-notes` `template` field is empty — _no template is applied to new daily notes yet._ A Templater-based daily note template is a natural next step.
-  `app.json` is owned by Nix at activation time but mutable at runtime
	- The Home Manager Obsidian module writes `.obsidian/app.json` as a symlink into the Nix store, making it read-only at the filesystem level.
	- Obsidian will fail silently or error when attempting to persist any settings change made through its UI — _the write is rejected by the store path._
	- The practical consequence is that this block is the exclusive mechanism for changing any `app` setting.
	- Any UI-side settings adjustment must be reflected here first, then applied via `home-manager switch`.
	- Settings changed in the UI between activations are lost on the next switch.
- `programs.obsidian.defaultSettings.app{};`:
	-  `followSymlinks` does not exempt symlinked files from Obsidian's file management operations
		- With `followSymlinks = true`, Obsidian indexes and edits symlinked files natively.
		- However, **Obsidian's rename and move operations follow the symlink to the real path and act on the actual file** — _a rename triggered from Obsidian's file explorer will rename the file inside the repo, not the symlink._
		- Structural operations _(rename, move, delete)_ on symlinked repo files must be performed from the terminal or from within the repo's tooling.
		- Obsidian should be treated as an editor and renderer for those files, not a file manager.

	-  `alwaysUpdateLinks` scope is limited to the vault index
		- `alwaysUpdateLinks` only rewrites links that Obsidian has indexed — _i.e. files within the vault boundary, including symlinked directories when `followSymlinks` is enabled._
		- It does not update links in files outside the vault, and it does not update links in files that were not open or indexed at the time of the rename.
		- In a multi-repo setup where the same document is referenced from multiple vaults or external tools, link integrity outside Obsidian remains a manual responsibility.

	-  `spellcheckLanguages` requires Obsidian's bundled dictionaries
		- `spellcheckLanguages` is only effective for languages whose dictionary is bundled with the installed Obsidian version.
		- The available set is determined by the `pkgs.obsidian` package version pinned in the flake.
		- If the vault is extended to cover content in a language whose dictionary is absent from that build, spell checking for that language will silently produce no results rather than erroring.

    - **`userIgnoreFilters` matches on directory name components only, not full paths or glob patterns.** 
        - A filter entry of `"target"` will exclude _any_ directory named `target` at any depth — including a legitimate notes folder the user might name `target`. 
        - If a future vault directory name collides with a filter entry, that directory will silently disappear from Obsidian's index with no warning.
        - Name vault directories deliberately to avoid collisions with the entries in the filter list.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Module group router|`./default.nix`|
|Sibling HM config|`./hm.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None yet_|
|Incident|_None recorded_|

---

<!-- METADATA
Module: modules/apps/productivity/obsidian.nix
Context: Home Manager
Created: 2026-06-10
Updated: 2026-06-11
-->
