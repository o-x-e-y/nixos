# Mario Kart Wii on this machine

Everything here is configured by [`wheelwizard-override.nix`](./wheelwizard-override.nix),
which pins and installs three things: **WheelWizard**, **Dolphin** and
**WiiCompiled**. They are one setup, not three alternatives — read *The two ways
to play* before removing anything.

## The two ways to play

| | Dolphin path | WiiCompiled path |
|---|---|---|
| What runs the game | Dolphin, emulating a Wii | A native binary, no emulator at all |
| Launched by | WheelWizard | `wiicompiled-retro-rewind` |
| Retro Rewind | Applied at runtime via Riivolution | Statically compiled into a separate binary |
| Game image | Any region | **PAL `RMCP01` only** |
| Setup cost | None | ~9 min build, ~20 GB transient |
| Extras | — | Unlocked framerate, any aspect ratio, high internal res |

WiiCompiled is a *static recompilation*: your disc is translated to C++ and
compiled on this machine. There is no interpreter and no PowerPC at runtime,
which is also why **Gecko codes / `.gct` files do nothing there** — there is no
code handler and no PPC memory to patch. Retro Rewind works only because its
Kamek/Pulsar `Code.pul` is fed through the recompiler as a build input. If you
want Gecko codes, that's the Dolphin path.

## Why Dolphin can't be removed

It is load-bearing even though you may never launch it to play:

- **WheelWizard requires it on Linux.** `ValidatePathSettings(requireDolphin:
  !IsRecompModeActive())`, and `IsRecompModeActive()` is
  `OperatingSystem.IsWindows() && …` — always false here. Without a Dolphin
  executable, WheelWizard stays *"setup not finished"* permanently.
- **WheelWizard is what installs and updates Retro Rewind**, into
  `~/.local/share/dolphin-emu/Load/Riivolution/WheelWizard/RetroRewind6` — which
  is the `--retro-dir` WiiCompiled compiles from. Drop Dolphin and the Retro
  Rewind update pipeline goes with it.

WheelWizard also **cannot drive WiiCompiled here**, so don't go looking for the
toggle: recomp mode is gated behind `OperatingSystem.IsWindows()` in three
places, and on Linux the recomp services are never even registered. That is why
WiiCompiled is driven from the command line below.

In WheelWizard's settings, point the Dolphin location at
`/run/current-system/sw/bin/dolphin-emu` — **not** a `/nix/store` path, which
would break on the next update.

## The game image

WiiCompiled validates in three steps and is pinned to one exact disc revision:

| Check | Required value |
|---|---|
| Game ID | `RMCP01` (PAL) |
| `sys/main.dol` sha256 | `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05` |
| `files/rel/StaticR.rel` sha256 | `16d9d146112541fefea701ecb5bc1a496f9d50e4a752fbb5b6778e7c6399f67d` |

It hashes those **two extracted files**, not the image, so the container format
is irrelevant — ISO, GCM, GCZ, CISO, WBFS, WIA and RVZ all work, and a stripped
update partition doesn't matter. Other regions are rejected on the header before
anything is extracted. Upstream asks that it be your own dump.

Verify a candidate in under a minute with `dolphin-tool`, which ships in the
`dolphin-emu` package:

```sh
dolphin-tool header -i <image>                                   # expect Game ID: RMCP01
dolphin-tool extract -i <image> -o /tmp/chk -s rel/StaticR.rel -q
sha256sum /tmp/chk/DATA/files/rel/StaticR.rel                    # expect 16d9d146…
```

`main.dol` sits in `sys/`, outside the FST, so `-s` can't reach it; it needs a
full `-g` extract. A matching `StaticR.rel` is signal enough to proceed.

## Building WiiCompiled

```sh
wiicompiled-setup install \
  --game ~/Games/mkwii-RMCP01-EU/mkwii-RMCP01-EU.wbfs \
  --retro-dir ~/.local/share/dolphin-emu/Load/Riivolution/WheelWizard/RetroRewind6 \
  --download-retro-wfc-payload
```

Drop `--retro-dir` and its payload flag for base-game-only. With it you get
**both** profiles. Then:

- `wiicompiled` — base game
- `wiicompiled-retro-rewind` — Retro Rewind
- `wiicompiled-setup check-products` — are the built binaries still current?
- `wiicompiled-setup uninstall`

Menu entries appear after the first successful install. Press **F10** in-game for
the settings bar (resolution, controllers, volume, `GCPadNew.ini` import).

## Getting WheelWizard past "setup not finished"

WheelWizard validates three paths on Linux, and **all three are required** —
`IsRecompModeActive()` is false here, so `requireDolphin` is always true:

| Setting | Value |
|---|---|
| `DolphinLocation` | `dolphin-emu` — the bare command is fine, and resolves through `$PATH` across updates |
| `UserFolderPath` | `~/.local/share/dolphin-emu` |
| `GameLocation` | the disc image, e.g. `~/Games/mkwii-RMCP01-EU/mkwii-RMCP01-EU.wbfs` |

`GameLocation` just means "where is your Mario Kart Wii disc image" — it is what
gets handed to Dolphin on launch. It accepts
`.iso/.gcm/.gcz/.ciso/.wbfs/.wia/.rvz` and doesn't care about region, but point
it at the PAL image so everything uses the one WiiCompiled requires.

**There is no WiiCompiled toggle to find.** The settings section is
`IsVisible = OperatingSystem.IsWindows()`, so it is never rendered here.
`EnableRecomp` still appears in `config.json`; setting it `true` by hand does
nothing, because `IsRecompModeActive()` ands it with `OperatingSystem.IsWindows()`.
WiiCompiled runs entirely outside WheelWizard on this machine.

## Controller bindings

[`dotfiles/wiicompiled/GCPadNew.ini`](../../dotfiles/wiicompiled/GCPadNew.ini) is
the source of truth — a real Dolphin profile, copyable straight to
`~/.config/dolphin-emu/GCPadNew.ini`.
[`home/programs/wiicompiled`](../../home/programs/wiicompiled) converts it with
`gcpad-to-controller.awk` and splices the result into `Config.toml`'s
`[controller]` section on activation, leaving `[paths]`, `[video]` and `[audio]`
alone. Rerunning is a no-op. `apps.wiicompiled.inputSource = "toml"` switches to
the hand-written [`controller.toml`](../../dotfiles/wiicompiled/controller.toml),
kept as a fallback for a WiiCompiled without the expression engine.

The repo is authoritative: **rebinding in the F10 bar survives until the next
rebuild**, which reverts it. `wiicompiled-config-backup` pulls the live section
back into `controller.toml` (only that form round-trips — the game writes
bindings, not the Dolphin profile they came from).

### Why the conversion is not just an import

WiiCompiled has its own `GCPadNew.ini` importer, and it is not used here, for
two reasons.

**It cannot read this profile.** Its name table
(`runtime/src/input_bindings.cpp`) holds Dolphin's XInput-style names — `Button
X`, `Button Y` — while Dolphin's SDL3 backend writes *positional* ones, `Button
W` and `Button N`. Those have no entry, so an import silently drops them. The
converter rewrites them to WiiCompiled's own vocabulary (`west`, `north`), which
its evaluator accepts as a fallback. **This is worth a PR upstream**: adding
`Button S/E/W/N` to `ButtonNames()` is a four-line fix.

**Freeing R2 needs a patched runtime.** Two layers had to give way. First,
aurora only synthesises the GameCube R *button* from the R2 axis when no real
button is mapped to it (`if (!rightTriggerSet && tr > activationZone)` in
`pad.cpp`), so a plain `r = "left_shoulder"` stops that. But that is not enough:
games read the **analog travel**, not the button bit — Mario Kart Wii drifts on
it — and aurora assigns `status[i].triggerRight` from the R2 axis
unconditionally. Only an expression can drive the analog value, and
`InputBindings::Apply()` merged it with `std::max`, so R2 kept drifting *and*
accelerated, while the button mapped to drift did nothing at all.

The fix is [`input-bindings-assign-analog.patch`](../../home/programs/wiicompiled/input-bindings-assign-analog.patch):
one line in `Apply()`, `std::max(target, scaled)` → `target = scaled`, so an
explicit binding replaces the default source instead of stacking on it. That
patch is why the converter emits an expression for `Triggers/L` and `Triggers/R`
in addition to the plain key — the plain key stops the button synthesis, the
expression takes over the analog. Both are needed. **This is the second thing
worth upstreaming**, alongside the missing positional button names.

Resulting layout: R2 accelerates, Square brakes, Triangle and Circle use items,
L1 drifts, R1 wheelies (D-pad Up), L2 is GameCube L.

Sticks are not remappable (`kControls` covers buttons and triggers only), and
bindings are positional and shared by every port. Wii U Pro Controllers are
skipped by the runtime, and Wii Remotes with an extension never reach this layer.

## Things that will bite you

- **The compiled game is not in the Nix store.** It lives in
  `~/.local/share/WiiCompiled/` (~220 MB of binaries, plus the workspace and the
  extracted disc). Inherent — it's built from *your* image, so it can't be a
  store path. It is **not** rebuilt by `nixos-rebuild` and **not** captured by
  any generation rollback.
- **A nixpkgs bump plus a garbage collect can break the built game.** It links
  against a specific Nix glibc; if that store path is collected, the binary
  won't start. Fix: re-run `wiicompiled-setup install …`.
- **`wiicompiled-setup --version` reports `0.2.22` on the 0.2.27 release.** That
  is an upstream inconsistency in their internal version constant, not a
  mispinned package.
- **Nothing is on `$PATH` until you rebuild** — `rebuild`, or `sudo nixos-rebuild
  switch --flake .#nixos`.
- **WheelWizard's settings live in `~/.config/CT-MKWII/`**, not
  `~/.config/WheelWizard` — `CT-MKWII` is the project's former name and the
  folder was never renamed. `config.json`, `RR.json`, `logs/` and `Mods/` are
  all in there.
- **The installed game is currently built from upstream `main`, not the pinned
  AppImage.** The input expression engine landed on 2026-09-05, hours after
  v0.2.27 was cut, so the pinned release cannot bind a control to a trigger at
  all. The binaries in `Install/` came from a local checkout staged at
  `~/.local/share/WiiCompiled/workspace-main`, built with nixpkgs' clang against
  v0.2.27's prebuilt aurora/Dawn (safe: the only aurora change on main is a GC
  Pocket+ rumble fix). **When the next release lands, bump
  `wiicompiled.version`, re-run `wiicompiled-setup install …`, and this
  divergence disappears** — the dotfiles and the splice need no changes, since
  the expression keys live in the same `[controller]` section.
- **Retro Rewind updates come from WheelWizard**, and WiiCompiled compiled a
  *snapshot* of `Code.pul`. After WheelWizard updates Retro Rewind, re-run
  `wiicompiled-setup install …` to pick it up; `check-products` will tell you
  when it has drifted.

## Why the module looks the way it does

Three non-obvious workarounds, all commented in detail in the `.nix`:

- **WheelWizard runs in an FHS sandbox** rather than being patchelf'd. Releases
  are self-contained *single-file* .NET bundles whose contents are found by
  absolute file offsets baked in at publish time; `patchelf` shifts them and the
  app dies with *"Arithmetic overflow while reading bundle"*. The binary has to
  stay byte-for-byte intact.
- **Dolphin is pinned to 2606a**, a security release hardening it against
  malicious game files and NetPlay peers (two GHSA advisories plus bounds checks
  in the GCZ, DOL and ELF readers and the NetPlay LZO decompressor). Drop the
  pin once the flake's nixpkgs catches up — it's a plain `overrideAttrs`.
- **WiiCompiled builds with the Nix toolchain, not its bundled one.** The
  bundled `ld.lld` needs `libicui18n.so.70` and its clang hunts for
  `crtbeginS.o` / `-lgcc` in a GCC sysroot no FHS tree provides. The FHS env
  also has to add `icu`, or the .NET translator aborts before doing anything.
  The module reimplements the AppImage's `AppRun` because AppRun stages its
  workspace with `cp -r` from a store path, landing read-only copies that the
  next version's `rm -rf` can't remove.

## Bumping versions

All three pins live in [`flake.nix`](../../flake.nix) under `wheelwizardOverride`:

| Pin | Current | Source |
|---|---|---|
| `version` / `hash` | 2.5.3 | WheelWizard `WheelWizard_Linux` release asset |
| `dolphin.{version,hash}` | 2606a | dolphin-emu git tag (source build) |
| `wiicompiled.{version,hash}` | 0.2.27 | `WiiCompiled-Setup-x86_64.AppImage` asset |

Change the version, set the hash to `lib.fakeHash`, build, and paste the real
hash from the error. All three are `x86_64-linux` only.
