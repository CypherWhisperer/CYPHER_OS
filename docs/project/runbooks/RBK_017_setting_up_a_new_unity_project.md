# Runbook: Setting Up a New Unity Project

<!-- A runbook is a step-by-step operational procedure. It answers: "How do I do X?" for X that happens regularly enough to standardize, or that is critical enough that you cannot afford to improvise. Runbooks are for DOING, not for UNDERSTANDING. Keep them terse. Every step is an action verb. -->

**Last verified:** not yet verified
**Host:** `cypher-nixos`
**Module:** `src/pkgs/dev/game_dev/` 
**Trigger:** `Reactive`
**Estimated time:** ~30 minutes (first run, including editor download)

---

## When To Use This Runbook

Starting a new Unity project for the Game Design and Development course, or first-time setup of the editor on a fresh machine.

---

## Prerequisites

- `cypher-os.pkgs.dev.gameDev.{enable,gui.enable,unity.enable,dotnet.enable}` set to `true`, and a successful switch.
- `programs.git.lfs.enable = true` (enforced by an assertion).
- VSCode with `extensions.lang.csharp.enable` and `extensions.gameDev.unity.enable` set to `true`.
- A Unity account (the Hub requires sign-in).
- Disk space for the editor download.

---

## Procedure

### Step 1 — Launch Unity Hub

```bash
unityhub
```

- **Expected output:** the Hub window opens; sign in with your Unity account.
- **If this fails:** check that `unityhub` is on `PATH` and that the unfree allowance is in place. See Troubleshooting.

---

### Step 2 — Install the pinned editor (first time only)

In the Hub: Installs → Install Editor → choose **6000.3 LTS** (see [ADR_025](../decisions/ADR_025_2026_09_29_unity_6000.3_lts_editor_pin.md)).

- **Expected output:** the editor appears under `~/Unity/Hub/Editor/`.
- **If this fails:** see Troubleshooting.

---

### Step 3 — Create the project

In the Hub: Projects → New project → pick a template → set the name and location → Create.

- **Expected output:** the editor opens the new project without crashing.
- **If this fails:** see Troubleshooting (editor crash on open).

---

### Step 4 — Initialise git and LFS

```bash
cd <project_dir>
git init
git lfs install
```

Add a Unity `.gitignore` that excludes at least `Library/`, `Temp/`, `Logs/`, `obj/`, `UserSettings/`, and generated `*.csproj` / `*.sln`. Add a `.gitattributes` tracking large binary asset types (for example textures, models, audio) with LFS.

- **Expected output:** `git lfs track` lists the patterns you added.
- **If this fails:** confirm `git lfs version` works; the module asserts git-lfs is enabled.

---

### Step 5 — Set the external script editor

In Unity: Edit → Preferences → External Tools → External Script Editor → choose VSCode.

- **Expected output:** double-clicking a script in the editor opens it in VSCode.
- **If this fails:** confirm the Unity extension is installed and that the Visual Studio Editor package is present in Package Manager. (Confirm this requirement against the extension's docs on first run.)

---

### Step 6 — Regenerate project files

In Unity: Edit → Preferences → External Tools → Regenerate project files.

- **Expected output:** `.sln` and `.csproj` files appear in the project root.
- **If this fails:** check the Unity console for package errors.

---

### Step 7 — Commit the declarative parts

```bash
git add Assets Packages ProjectSettings
git commit -F- <<EOF
chore: initial Unity project (6000.3 LTS)
EOF
```

- **Expected output:** `ProjectSettings/ProjectVersion.txt` and `Packages/manifest.json` are in the commit.
- **If this fails:** check the `.gitignore` is not excluding them.

---

### Step 8 — Verify

Open a script from Unity in VSCode.

- **Expected result:** C# Dev Kit and the Unity extension activate without runtime errors, completions and diagnostics work, saving formats with CSharpier, and the Unity debugger can attach to the running editor.

---

## Troubleshooting

### Editor crashes when opening a project

Symptom: the editor closes on project open, with a missing `libtinfo.so.6` in the log. This is the known crash on the 6000.6 line ([NixOS/nixpkgs#561247](https://github.com/NixOS/nixpkgs/issues/561247)). Confirm the editor is 6000.3 LTS. If 6000.3 also fails, record it and consider the fallback in ADR_025.

### C# Dev Kit cannot find the .NET runtime

Symptom: the extension reports a missing runtime. Check `dotnet --info` and `echo $DOTNET_ROOT`. Known issue: [NixOS/nixpkgs#389351](https://github.com/NixOS/nixpkgs/issues/389351). The `DOTNET_ROOT` value in the module is not yet verified.

### No completions or diagnostics

Symptom: the language server does not attach. Regenerate project files (Step 6) so a `.sln` exists, then reload VSCode.

### Debugger does not attach

Symptom: attach fails. Known issue for the nixpkgs C# Dev Kit debugger: [NixOS/nixpkgs#449679](https://github.com/NixOS/nixpkgs/issues/449679); check whether it applies on the channel in use.

---

## Rollback

Close the editor and delete the project directory, or `git revert` the initial commit. Removing the installed editor: uninstall it from the Hub (Installs). This procedure changes nothing in the Nix configuration.

---

## Related

- ADR:
    - [ADR_025](../decisions/ADR_025_2026_09_29_unity_6000.3_lts_editor_pin.md)
    - [ADR_026](../decisions/ADR_026_2026_09_29_share_roslyn_ls_and_csharpier_across_vscode_and_neovim.md)
    - [ADR_027](../decisions/ADR_027_2026_09_29_use_separate_debuggers_for_plain_Csharp_and_unity.md)
- Journal: [2026_09_29_game_dev_tooling](../../development/journal/2026_09_29_game_dev_tooling.md)
- Module doc: [game_development_setup](../../source_docs/src/pkgs/dev/game_dev/game_development_setup.md)

---

<!-- METADATA Created: 2026-09-29 Updated: 2026-09-29 Tested by: Cypher Whisperer -->