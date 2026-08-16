---
description: Load the summer training block — what it is for, how the repo drives Garmin and intervals.icu, and the rules the block has earned
argument-hint: [question or focus]
allowed-tools: Read, Grep, Glob, Bash(date:*)
---

Starter context for coaching work on the summer training plan
(`~/Documents/summer-training`). **This command pulls no new data** — use
`/fetch-rides` for that, and for the caveats on reading intervals.icu.

Today: !`date +"%A %-d %B %Y"`

## The block

A **10-week FTP build, Jun 22 – Aug 30 2026**, aimed at one number: raise a tested
FTP of **275 W** (289 W average over the 20-min test on 30 Jun) to **≥300 W**, or
~4.1 → ~4.5 W/kg at 66 kg. It is settled by a **final 20-min test on Mon Aug 24** —
≥316 W average means the goal is hit.

The shape is **two quality days a week on a deep Z2 base**: one threshold or
sweet-spot session, one VO2, everything else easy enough to recover from them. The
rider already has a healthy top end (565 W for 1 min, 440 W for 8×1 min); the
missing stimulus is *accumulated time at and just below threshold*, so the block
progresses **time-in-zone before watts** — 48 min at 273 W on Jul 30, 45 min at
275 W on Aug 13, 54 min on Aug 17.

Zones at FTP 275: **Z1 <154 · Z2 154–209 · Z3 209–250 · Z4 250–292 · Z5 292–333 ·
Z6 333–415 · Z7 >415 W.**

Weeks: 1 reset & test · 2–3 build · 4–5 Zeeland and the Ospel crit · 6 peak load ·
7 deload · 8 peak intensity · 9 final sharpening (Mon Aug 17's 3×18min is the
headline session) · 10 test, the Limburg loop on Wed Aug 26, and the R&TC
Buitenlust club ride.

Two constraints run through every week. The rider works **cinema shifts** that log
no TSS but cost a day on the feet, so sessions are fitted to the roster, not the
other way round. And it is a **Dutch summer** — heat is the single strongest
predictor of whether a quality session lands.

## Where everything lives

```
workouts/workouts.json ──┬──▶ summer-training-plan.typ  (the plan PDF, via json())
  the single source      ├──▶ garmin/push.py            (structured workouts on the watch)
  of truth for every     └──▶ icu/push.py               (planned load on the icu calendar)
  structured workout
review/log.json  ─▶ review/sessions.py ─▶ review/sessions.json ─▶ the plan's session log
nutrition/fuel.py ─▶ nutrition/fuel.json ─▶ the plan's per-day Fuel badge
```

- `summer-training-plan.typ` — the plan itself, ~480 lines. Week tables with a
  `session:`, a `work:` roster field, and post-hoc "*Done —*" prose. Ends with
  **How to Adjust**, nine rules. `training-plan.typ` is its template
  (`week-table`, `workout-viewer`, `session-log`, `make-zones`).
- `workouts/workouts.json` — `ftp`, `power_bounds`, 24 structured `workouts` and 31
  one-line `notes` (the easy/recovery/endurance days), keyed by ISO date. **Edit
  workouts here, never downstream.**
- `review/` — `log.json` holds only the two things an API cannot know: what was
  prescribed and the one-clause verdict. Everything objective is pulled.
- `nutrition/` — `fuel.py` builds daily kcal/carb targets from planned watts, the
  `work:` shift hours, and intervals.icu.
- `docs/superpowers/` — design docs and implementation plans for the tooling.

## `garmin/push.py` — structured workouts onto the watch

Reads `workouts.json`, runs it through `transform.py` (min→sec, explicit power →
±10 W alert band, zones → watt bands, nested repeats, `skip-last-recovery`) and
`garmin_dto.py` (the exact Garmin payload), then uploads and **schedules** each
workout on the Garmin calendar as `STP <date> · <name>`.

```sh
nix-shell --run "python garmin/dry_run.py"        # print every workout as a tree, no account
nix-shell --run "python garmin/push.py --login"   # ONE TIME: 2FA, caches a token
nix-shell --run "python garmin/push.py --days 14"          # offline preview
nix-shell --run "python garmin/push.py --days 14 --push"   # create + schedule
nix-shell --run "python garmin/push.py --prune --push"     # delete past-dated STP workouts
```

- **Dry-run by default**; `--push` is the only thing that writes.
- **Idempotent by content hash** — `.push-state.json` records what went up, so
  editing one workout re-pushes only that one. Only dates on/after today.
- Needs the flake shell (garth + garminconnect, pinned to nixos-25.11); direnv
  loads it on `cd`. Credentials come from sops, never the repo.
- `notes` days become **one-step alert-free workouts** so they appear on the
  calendar; rest days are omitted. `--no-notes` skips them.
- Push a **short window**. The plan adapts constantly — months of scheduled
  workouts are just cleanup later.

## `icu/push.py` — planned load onto the intervals.icu calendar

Garmin's *planned* workouts never sync back to intervals.icu; only completed
activities do. Without this, intervals.icu cannot project anything. This script
posts each plan day as calendar-event text, and **intervals.icu parses it
server-side and computes `moving_time` and `icu_training_load` itself** — so the
week shows a projected TSS and the fitness chart projects CTL/ATL/TSB forward
through the rest of the block. That projection is what makes "Thursday lands at
TSB ~-8" a statement rather than a guess.

```sh
python3 icu/push.py --days 16            # offline preview (stdlib only, no nix shell)
python3 icu/push.py --days 16 --show     # ... with the full workout text
python3 icu/push.py --days 16 --push     # create/update, then report TSS by week
```

- Same IR as the Garmin build, with two deliberate differences: `tol_w=0` (275 W
  renders as `275W`, not a ±10 W band) and power alerts **unconditionally**, since
  an untargeted step contributes nothing to the load estimate and the 20-min test
  is the block's biggest session.
- **No local state.** Ownership is by `external_id` (`stp-<date>`); every run
  re-reads the calendar, so it self-heals and never touches a hand-made event.
- `render.py`'s `EASY_PCT` (50%) and `ENDURANCE_PCT` (65%) price everything the
  plan leaves untargeted. Notes are 31 of 55 days — drop them and the projected
  weekly load lands at roughly half the real figure.

## Keeping the plan coherent

Four artefacts go stale independently. After changing anything:

| Changed | Re-run |
|---|---|
| a workout in `workouts.json` | `garmin/push.py --push`, `icu/push.py --push` |
| any session or `work:` field in the `.typ` | `python nutrition/fuel.py`, and update `UNSTRUCTURED` in `fuel.py` for prose sessions |
| a ride was completed | `python review/sessions.py` (and add the verdict to `review/log.json`) |
| anything at all | `typst compile summer-training-plan.typ` — system typst, not the flake |

**`UNSTRUCTURED` in `fuel.py` is the one that silently rots.** A prose session that
is neither in `workouts.json` nor in that table contributes zero exercise energy,
and nothing warns you.

## The rules this block earned

Read `How to Adjust` at the end of the plan for all nine. The ones that change
decisions most:

1. **Heat is the variable; the clock is only the lever.** Judge temperature *during
   the reps*, not the day's peak — ~8 bpm separates 27 °C from 30 °C at the same
   watts, which looks exactly like under-recovery. 26–28 °C, consider moving the
   start; 28 °C+, change course. **Never rescale FTP off a hot session.**
2. **Hold FTP 275 to the Aug 24 test.** Targets are ridden as ceilings you are
   allowed to beat, noted rather than rescaled. The test is what moves the number.
3. **Progress time-in-zone first, watts last.** Raise total work, then rep length,
   then watts. Prefer 5×4 over 4×5, 4×12 over 3×16.
4. **Trust feel, ignore RPE.** Feel runs 1–5 with **1 strongest** and orders the
   block almost perfectly; RPE reads 9 on six of eight sessions including the best
   and the worst. The rider's free-text note is worth more than either.
5. **An endurance day has a target, not a ceiling.** 155–200 W *held*. Z1 transport
   and commutes are recovery — real, worth keeping, and **not** the endurance day.
   Budgeting them as one is the error that cost this block its aerobic base in
   Weeks 5–7 (22 min of Z2 on Jul 29 against 135 min on Aug 11). Watts are the
   guardrail; read HR for drift (>~8 bpm at the same power = the ride changed).
6. **Fit quality to the work calendar.** Hard sessions on a free day, or on a work
   day *before* an evening shift. All-day shifts stay easy or rest. Never a hard
   session the day before a day that cannot absorb it.
7. **Long reps need a number, not feel.** Every long-rep session that broke did so
   because rep 1 drifted up; the two that went cleanly were ridden to a hard ceiling.

## Working style

- **The session log is the evidence base.** `review/sessions.json` carries load,
  IF, temperature over the reps, TSB on the morning, RPE, feel and the rider's own
  note for every quality session. **Cite a row; don't retell it**, and don't write
  week-note essays — outcomes belong in `review/log.json` as a prescribed/delivered
  /verdict row.
- **Never silently edit the plan.** Propose a change with its reasoning and let the
  rider decide. When a change is accepted, the plan records *what changed, when,
  and why* inline — that audit trail is how the corrections above got caught.
- **Corrections are first-class.** Several conclusions in this plan were wrong and
  were overturned by re-reading the data (Jul 3 was not a failure; rep length was
  standing in for heat). Say so plainly in the document when it happens.

## Task

Orient first, in both cases:

1. Read the plan's **Overview & Principles**, the **week table covering today**,
   and **How to Adjust**. The file is large; grep for the week heading rather than
   reading all 480 lines.
2. Read `review/sessions.json` for what the block has actually delivered.

Then:

**$ARGUMENTS**

If there is a question above, that is the job — answer it, grounded in the plan
and the session log, citing the rows and rules it turns on. Read further into the
plan or the tooling if the question needs it, and say plainly when the evidence
does not settle it. Don't preface the answer with a status report.

If nothing is above, this was a bare `/coach`: report where the block stands in a
few lines — the current week and its intent, the next quality session and its
gates, and anything that looks stale or unresolved. Then stop and wait.

Either way: propose changes, don't make them. Nothing gets edited or pushed until
the rider says so.
