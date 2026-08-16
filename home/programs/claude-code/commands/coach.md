---
description: Coach the summer training block — the plan, the tooling, the rules it earned, and optionally recent rides and nutrition
argument-hint: [notes, a question, and/or "pull the last N days"]
allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(intervals-icu:*), Bash(nix-shell:*), mcp__cronometer__get_food_log, mcp__cronometer__get_daily_nutrition, mcp__cronometer__get_nutrition_scores, mcp__cronometer__get_biometrics
---

Coaching context for the summer training plan (`~/Documents/summer-training`),
plus the tools to pull recent data when the prompt asks for it.

Today: !`date +"%A %-d %B %Y"`

## The block

A **10-week FTP build, Jun 22 – Aug 30 2026**, aimed at one number: raise a tested
FTP of **275 W** (289 W average over the 20-min test on 30 Jun) to **≥300 W**, or
~4.1 → ~4.5 W/kg at 66 kg. It is settled by a **final 20-min test on Mon Aug 24** —
≥316 W average means the goal is hit.

The shape is **two quality days a week on a deep Z2 base**: one threshold or
sweet-spot, one VO2, everything else easy enough to recover from them. The rider
already has a healthy top end (565 W for 1 min, 440 W for 8×1 min); the missing
stimulus is *accumulated time at and just below threshold*, so the block progresses
**time-in-zone before watts** — 48 min at 273 W Jul 30, 45 min at 275 W Aug 13,
54 min Aug 17.

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
                          ▲
      what was eaten ─────┘  Cronometer, via the `cronometer` MCP (read-only)
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
  `work:` shift hours, and intervals.icu. It prescribes; it never sees intake.
- `docs/superpowers/` — design docs and implementation plans for the tooling.

# Pulling data

**Nothing is pulled unless the prompt asks for it.** A bare `/coach`, or a question
the repo already answers, reads files only. Fetch when the prompt asks for recent
training ("pull the last 3 days", "how did this week go"), or when a claim needs
evidence the repo does not hold.

## intervals.icu — athlete i563199, synced from Garmin

`intervals-icu activities <days>` is the entry point. In its JSON: `np_w` =
normalized power, `intensity` = IF × 100, `load` = training load (TSS), `h` =
moving time in hours. Activity `id`s feed the drill-downs — prefer the summary, and
drill down only where the review needs it:

- `intervals-icu intervals <id>` — auto-detected intervals. **Not the laps** — see below
- `intervals-icu wellness [days]` — weight, resting HR, sleep, HRV
- `intervals-icu activity <id>` — full activity JSON (large; rarely needed)
- `intervals-icu streams <id> [types]` — per-second data (very large; deep dives only)
- `intervals-icu streams <id> temp` — ambient temperature; pull for **every** quality
  session before drawing conclusions from HR
- `intervals-icu get <path>` — anything else, see https://intervals.icu/api-docs.html

## Structured sessions: read the intent first

Sessions pushed from this repo are named `STP <date> · <name>`. Match on that
**name**, not the activity date — sessions get ridden a day late. The intended steps
live in `workouts/workouts.json` under `.workouts["<date>"].steps`. Judge the ride
against *those*, not against whatever intervals.icu detected.

`intervals-icu intervals <id>` distorts outdoor sessions in two known ways:

- **It splits reps at junctions.** Brief coasting becomes a 6–20 s `RECOVERY`,
  turning three reps into eight fragments. Merge `WORK` intervals separated by gaps
  under ~30 s before reading anything into the structure.
- **It charges rep ramp-ups to the preceding recovery.** A `WORK` interval doesn't
  open until power stabilises, so the ramp-in inflates the recovery's average watts
  and shortens the rep.

intervals.icu knows the true lap count (`icu_lap_count` on the activity) but exposes
no laps endpoint — `/activity/<id>/laps` 404s. The `distance` stream is available if
5 km autolaps need reconstructing by hand.

**Never call a fade from power alone.** A real fade is power declining *while HR
holds or climbs*. Split any suspect block into quarters and check both channels —
falling HR alongside falling power is a deliberate ease-off, not a failure. Use
`intervals-icu streams <id> watts,heartrate` piped into `nix-shell -p python3`.

## Heat: get the temperature before reading HR

Rule 1 below is the decision; this is how to read it. Use the stream, not the
summary field:

- `intervals-icu streams <id> temp` is a real per-second series, not a start-only
  value — Aug 1 2026 tracks 29 °C down to 20 °C across an evening.
- Average it **over the work intervals**, not the whole ride. The activity's
  `average_temp` can badly misrepresent them: Aug 1 averaged 23.5 °C while its first
  hour sat at 29 °C.
- Resolution is integer °C, and the sensor sits on the head unit, so it carries
  radiant and body heat. Reliable for comparing rides against each other; not a
  shaded air reading.

Worked comparison: Jul 30's 4×12 held 273 W at HR 163–165 with its reps at
**26.8 °C**; Aug 3's 2×15 at the same watts ran its reps at **30.4 °C**, hit HR 181,
and lost rep 2. Same rider, four days apart, same nominal freshness.

**Time of day is the lever, not the variable.** Jul 15 failed at 10:03 in 27 °C;
Jul 27's VO2 5×5 landed in full at 16:44 in 23 °C. Judge the temperature, then use
the clock to control it — start quality before 10:00 when the forecast tops 28 °C.

## `weather` — forecasting the window before the session

Rule 8 says check the forecast the evening before. `weather` is the tool for it —
Open-Meteo through a curl wrapper, no API key, default location Beek en Donk
(`-l eindhoven | helmond | <lat>,<lon>` to move it).

```
weather now                    weather day +1 [12-15]      hourly table
weather today [12-15]          weather window +1 12-15     summary over a window
```

`window` is the one to reach for: it collapses a candidate session window into
mean/range temperature, total rain, gusts and cloud — the fields rules 1 and 8
actually turn on. Dates before today come from the ERA5 archive, today and later
from the forecast. **They are not interchangeable**: measured on Aug 13 2026 they
disagree by ~1.4 °C, which is the same size as the offset below, so never quote the
forecast endpoint's `past_days` for a ride that already happened.

**Air temperature predicts head-unit temperature almost directly.** The plan used
to assume the head unit read far higher because the sensor carries radiant load —
the Aug 13 cell predicted 26–31 °C against an air temperature of 20 °C. Measured
against `temp_work` in the session log the offset is about **+1 °C**:

| | air over the reps | head unit | Δ |
|---|---|---|---|
| Aug 13, reps 08:30–09:25 | 20.0 °C | 20.5 | +0.5 |
| Aug 15, reps ~10:15–11:45 | 25.2 °C | 25.8 | +0.6 |

So a forecast can be read straight against rule 1's 26–28 / 28+ gates with a +1 °C
nudge, which is what the `window` summary prints. Two points, and both rep windows
were inferred from the session structure rather than the streams — widen the check
if a call sits right on a gate.

Wind is worth a look on the same call: flat exposed roads plus gusts make a steady
275 W materially harder to hold, and it costs nothing to read it off the same table.

## Cronometer — what was actually eaten

Logged intake comes from the **`cronometer` MCP** (`mcp__cronometer__*`). The tool
descriptions say what each call does; they do not say the three things that matter.

- **`fuel.json` is the target, Cronometer is the outcome.** The comparison worth
  making is `get_daily_nutrition(date)` against `nutrition/fuel.json`'s `total_kcal`
  and `carb_g` for the same day. Nothing else closes that loop.
- **Ignore Cronometer's own target.** Its `total_target_kcal` knows nothing about
  training load — on Aug 16 it read 2631 against `fuel.py`'s 3610 and called the
  rider ~600 kcal *over* while they were ~380 kcal *under*. It points the wrong way
  on a build block. Never quote it as a verdict.
- **`get_biometrics` is not a weigh-in log.** It is a carry-forward series: it
  returns the boundaries of whatever range you ask for with the last known value
  repeated. Two different windows both came back as two points at 65.2 kg. **Weight
  comes from `intervals-icu wellness`**, which hooks into Garmin directly and is what
  `fuel.py` reads; Cronometer's figure is hand-entered and goes stale.

Pull a day when the question turns on fuelling — a session that heat and TSB do not
explain, or the day before a headline session. Under-carbing before quality is a
real finding; one day's total on an easy week is noise. The five diary-writing tools
are denied at the harness: cite a day, don't edit one.

# The tooling

## Pushing the plan out — `garmin/push.py` and `icu/push.py`

Both read `workouts.json` and are documented in full in `garmin/README.md` and
`icu/README.md`. Read those before running either; what matters here is why they
exist and what they cost.

- **`garmin/push.py`** puts structured workouts on the watch, scheduled on the
  Garmin calendar as `STP <date> · <name>` — the name the completed activity comes
  back under, which is how a ride gets matched to its intent.
- **`icu/push.py`** exists because Garmin's *planned* workouts never sync back to
  intervals.icu; only completed ones do. It posts each plan day as calendar text,
  which intervals.icu parses server-side and prices itself — projecting weekly TSS
  and CTL/ATL/TSB forward. That projection is what makes "Thursday lands at
  TSB ~-8" a statement rather than a guess. Its `render.py` prices untargeted days
  too; drop those and projected load lands at roughly half the real figure.
- **Both are dry-run by default** — `--push` is the only thing that writes. Garmin
  is idempotent by content hash, icu by `external_id`, so re-running is safe.
- **Push a short window.** The plan adapts constantly; months of scheduled workouts
  are just cleanup later.

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

# The rules this block earned

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

# Task

Orient first, always:

1. Read the plan's **Overview & Principles**, the **week table covering today**,
   and **How to Adjust**. The file is large; grep for the week heading rather than
   reading all 480 lines.
2. Read `review/sessions.json` for what the block has actually delivered.

Then:

**$ARGUMENTS**

It may carry notes on a ride just done, a question, a request to pull data, or
several at once. Take it as written.

- **Asks for data** — "pull the last 3 days", or a claim only the API can settle:
  fetch, then review against the current week. Did quality sessions match their
  targets in watts, duration and reps (temperature over the reps before blaming
  fitness or fatigue)? Easy days actually easy, IF below ~0.75? Volume vs plan?
- **Asks a question** — answer it from the plan and the session log, citing the
  rows and rules it turns on. Pull data only if the question needs it.
- **Carries notes on a session** — record them as a prescribed/delivered/verdict
  row for `review/log.json`, not as prose.
- **Empty** — a bare `/coach`: where the block stands in a few lines. Current week
  and its intent, next quality session and its gates, anything stale or unresolved.
  Pull nothing, then stop and wait.

No status-report preamble. Say plainly when the evidence doesn't settle it. Flag
what the plan should change with its reasoning — **propose changes, don't make
them.** Nothing gets edited or pushed until the rider says so.
