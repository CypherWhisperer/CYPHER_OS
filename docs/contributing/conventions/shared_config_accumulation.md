# Convention: Internal Accumulator Options for Multi-Leaf Generated Content

**Status:** Active
**Applies to:** any case where several leaf files each need to contribute a fragment of one generated artifact (e.g.., VSCode (`src/pkgs/dev/ide/vscode/*`)'s  `settings.json`  config file deployed to multiple forks/targets (VSCode, Cursor and Antigravity)), and only one place should actually write it out.

## Pattern

Declare an attrs-typed option not meant for user configuration *(name it distinctly, e.g. `_sharedSettings`, and document it as internal in its description).*

Each contributing leaf sets its own slice via ordinary `config.<path>._sharedSettings = { ...its own keys... };` — the module system deep-merges attrs-typed options across every contributing module automatically, the same mechanism that already lets every category's `assertions` *(list-typed)* accumulate without conflict.

Exactly one file — *the category's aggregator or "core config" file* — reads the fully-merged option and performs the actual write(s):

```nix
config = lib.mkIf cfg.enable {
  programs.<app>.someSetting = cfg._sharedSettings;
  xdg.configFile."<forkA>/settings.json".text = builtins.toJSON cfg._sharedSettings;
  xdg.configFile."<forkB>/settings.json".text = builtins.toJSON cfg._sharedSettings;
};
```

## Why not have every leaf write the file directly

Options typed as plain scalars (a string, `xdg.configFile.<path>.text`) only allow multiple modules to agree on an *identical* value — *real, diverging content from two different leaves throws a hard "conflicting definition" eval error.*

The accumulator option exists specifically to avoid every leaf needing to know about (or agree on) the full output — each contributes independently, and only the merge target needs to be write-safe.

## Caution

Two leaves setting the *same* nested key differently still conflicts — this pattern avoids the write-collision, not genuine data collisions. ***Keep each leaf's contribution to keys it alone owns.***