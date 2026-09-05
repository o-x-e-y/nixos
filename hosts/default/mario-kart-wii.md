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
