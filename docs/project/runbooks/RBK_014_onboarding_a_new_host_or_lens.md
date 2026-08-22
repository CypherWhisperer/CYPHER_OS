# Runbook: Onboarding a New Host or Lens

**Last verified:** 2026-08-22
**Host:** `arch` / `debian` / `fedora` / `opensuse` (any non-NixOS lens)
**Module:** `hosts/<lens>/home.nix`, `flake/home-configurations.nix`
**Trigger:** Reactive
**Estimated time:** ~30 minutes

---

## When To Use This Runbook

Bringing up CypherOS's Home Manager configuration on one of the already-stubbed non-NixOS lenses *(Arch, Debian, Fedora, openSUSE),* or a genuinely new host on any lens.

These lenses run **standalone** Home Manager — no NixOS graph underneath, so `osConfig` is unavailable (see [ADR_024](../decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md)).

## Prerequisites

- Home Manager installed on the target machine per its own distro's instructions *(outside this flake's control on a non-NixOS host).*
- Know the host's intended profile *(`desktop`/`server`)* up front — *it must be set explicitly here, unlike the NixOS-integrated host.*

## Procedure

### Step 1 — Create the host's `home.nix`

```bash
mkdir -p hosts/<lens>
touch hosts/<lens>/home.nix
```

### Step 2 — Set `profile.active` and `lens.current` explicitly

```nix
{
  home.username = "cypher_whisperer";
  home.homeDirectory = "/home/cypher_whisperer";   # confirm actual path on this distro

  cypher-os.profile.active = "desktop";   # or "server" — set explicitly, no osConfig here
  cypher-os.lens.current   = "<lens>";    # "arch" | "debian" | "fedora" | "opensuse"
}
```

This is the one accepted duplication point per ADR-024 — there is no NixOS graph on this lens for these values to be read from.

### Step 3 — Register the `homeConfigurations` entry

In `flake/home-configurations.nix`, uncomment/add the stubbed entry for this host, following the existing `cypher_whisperer@cypher-nixos` shape, pointing at `../modules/home/default.nix` (shared aggregator) plus `../hosts/<lens>/home.nix`.

### Step 4 — Verify the fonts category behaves correctly

```bash
home-manager build --flake .#cypher_whisperer@<lens>
```

**Expected result:** since `lens.current != "nixos"`, the full font package set installs via Home Manager *(there's no system-level `fonts.packages` to rely on here)* — confirm the font packages appear in the build output.

### Step 5 — Switch

```bash
home-manager switch --flake .#cypher_whisperer@<lens>
```

---

## Troubleshooting

### An option assumes `osConfig` is present and evaluation fails

A module wasn't written with the `osConfig ? null` fallback pattern from [ADR_024](../decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md). Fix the module to handle the standalone case rather than working around it on this host.

### Fonts are missing after switch

Check `lens.current` was actually set to something other than `"nixos"` in Step 2 — if left unset or defaulted wrong, the fonts module may assume system-level fonts exist when they don't on this lens.

## Rollback

`home-manager switch` to the previous generation *(`home-manager generations`, then switch to the prior one)* if the new host's config produces a broken environment.

## Related

- ADR: [ADR_024](../decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md), [ADR_011](../decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md)

---

<!--
METADATA
Created: 2026-08-22
Updated: 2026-08-22
Tested by: Cypher Whisperer
-->