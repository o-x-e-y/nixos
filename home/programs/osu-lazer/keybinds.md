# osu!lazer keybinds — dvorak → gust

These are the bindings migrated from the old osu! **stable** config
(`osu!lucoe.cfg`, set under a **dvorak** software layout) to the current **gust**
layout (kanata). osu!lazer keeps keybinds in a binary database (`client.realm`),
so they **can't** be set from a file in the repo — enter them **once** in
*Settings → Input* in osu!lazer, then snapshot the realm (see below) so it
persists via `config/osu-client.realm`.

## How to read this

- **Press (gust)** is the character now printed on the key under gust — bind to that.
- Equivalently, **Phys** is the physical key (US-QWERTY label) you used to press;
  it's the same physical position as before, so muscle memory carries over.
- If lazer ever shows a name different from "Press (gust)" (the OS xkb layout is
  dvorak under kanata), **trust the physical key** — that's the source of truth.
- Layout-independent keys (F-keys, arrows, Space, Tab, Esc, Insert, Shift/Alt,
  number row) are unchanged and not listed except where relevant.

## osu! (standard)

| Setting | Old (dvorak) | Phys | Press (gust) |
|---|---|---|---|
| Left button   | OemSemicolon | Z | **Comma** `,` |
| Right button  | Q            | X | **Period** `.` |
| Smoke         | LeftShift    | — | LeftShift (unchanged) |

## osu!taiko

| Setting | Old | Phys | Press (gust) |
|---|---|---|---|
| Inner Left  | OemComma  | W | U |
| Outer Left  | OemQuotes | Q | Semicolon `;` |
| Inner Right | Multiply (numpad) | — | **Equal `=`** (was numpad; proposed) |
| Outer Right | Subtract (numpad) | — | **BackSlash `\`** (was numpad; proposed) |

## osu!catch (fruits)

| Setting | Old | Phys | Press (gust) |
|---|---|---|---|
| Left  | OemQuotes | Q | Semicolon `;` |
| Right | OemComma  | W | U |
| Dash  | Subtract (numpad) | — | **BackSlash `\`** (was numpad; proposed) |

> Numpad replacements are my proposal (you have no numpad now): rightmost keys,
> spread out for 6KRO. Adjust to taste — your board's exact ghosting/blocking
> pairs are unknown without the model.

## osu!mania (stage layouts)

| Keys | Old | New (gust) |
|---|---|---|
| 1K | Space | Space |
| 2K | U H | C H |
| 3K | U Space H | C Space H |
| 4K | E U H T | A C H T |
| 5K | E U Space H T | A C Space H T |
| 6K | O E U H T N | I A C H T N |
| 7K | O E U Space H T N | I A C Space H T N |
| 8K | A O E U H T N S | E I A C H T N S |
| 9K | A O E U Space H T N S | E I A C Space H T N S |

> 6KRO note: 7K–9K want 7–9 simultaneous keys, which a 6-key-rollover board can't
> all register at once. That's a hardware limit, not a binding issue.

## Mods (mod-select shortcuts)

| Mod | Old | New | Mod | Old | New |
|---|---|---|---|---|---|
| Easy        | OemQuotes    | Semicolon | Sudden Death | O | I |
| No Fail     | OemComma     | U         | Double Time  | E | A |
| Half Time   | OemPeriod    | O         | Hidden       | U | C |
| Hard Rock   | A            | E         | Flashlight   | I | Y |
| Relax       | OemSemicolon | Comma     | Autopilot    | Q | Period |
| Spun Out    | J            | P         | Auto         | K | G |
| Score V2    | X            | Quote `'` |  |  |  |

## Editor

| Action | Old | New | Action | Old | New |
|---|---|---|---|---|---|
| New combo  | OemQuotes    | Semicolon | Whistle    | OemComma  | U |
| Finish     | OemPeriod    | O         | Clap       | L         | V |
| Grid snap  | Y            | J         | Dist snap  | F         | Q |
| Note lock  | N            | N         | Help       | D         | D |
| Jump begin | OemSemicolon | Comma     | Play begin | Q         | Period |
| Audio pause| J            | P         | Jump end   | K         | G |
| Grid change| I            | Y         |  |  |  |

(Select/Normal/Slider/Spinner tools stay 1/2/3/4; nudge left/right stay arrows.)

## Tablet

The tablet is osu-only, so we use osu!lazer's **bundled** OpenTabletDriver (no
system driver). Set it up in *Settings → Input → Tablet*:

- Tablet: **Intuos P S**, physical area **152 × 95 mm**.
- The old Windows backup mapped the **full area** — so start from full
  (Area 152 × 95 mm, centered) and shrink to taste.

These values live in `input.json` (`AreaSize`/`AreaOffset` in mm, rotation,
pressure, screen mapping) — **not** in `client.realm`.

## Persisting your setup

osu!lazer rewrites its config at runtime, so these files are seeded copy-if-missing
into `~/.local/share/osu/` as **writable copies** (nothing is symlinked read-only —
the activation `cp`s and `chmod u+w`s them). Four files are persisted:

| File | Holds |
|---|---|
| `client.realm`  | keybinds, skins, beatmap index (binary) |
| `input.json`    | tablet area / rotation / pressure / screen mapping |
| `framework.ini` | window mode, audio device, volumes, renderer, frame sync |
| `game.ini`      | gameplay / UI / editor settings |

After configuring in-game, snapshot them with:

```
osu-config-backup          # writes to this module's config/ (pass a dir to override)
```

On a fresh machine the activation restores each file if it isn't already present.
They're point-in-time snapshots — re-run `osu-config-backup` to update.

**Credentials:** the only secret is the login `Token` in `game.ini`.
`osu-config-backup` strips that line on copy, so nothing committed carries a
credential — just log in once per machine (the token is short-lived and rotates
anyway, so storing it would be pointless).

**Not backed up:** `client.realm.lock`, `client.realm.note` (a FIFO) and
`client.realm.management/` are transient — Realm regenerates them whenever it
opens `client.realm`. (Ignore the bundled README's "back up the whole folder"
advice; those sidecars must not be restored.)
