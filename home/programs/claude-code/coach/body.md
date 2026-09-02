Coaching context for the summer training plan (`~/Documents/summer-training`),
plus the tools to pull recent data when the @PROMPT@ asks for it.

@TODAY@

## The block — closed 1 Sep 2026

A **10-week FTP build, Jun 22 – Aug 30 2026**, aimed at one number: raise a tested
FTP of **275 W** (288.6 W over the 20-min test on 30 Jun) to **≥300 W**. It ran one
day long, and **it is finished**.

**The result: 309.0 W for 20 min on Tue 1 Sep → FTP 293**, adopted at 293 by the
rider's call. Against Jun 30 the whole curve moved — 3 min +18.3, 5 min +15.6,
8 min +19.1, 10 min +20.3, 15 min +19.5, 20 min +20.4 W — and it is flat from 5 to
15 min (317 / 317 / 315 / 312), which is a threshold shift rather than a good day at
the top end. **274 → 293 W, +7.1%, at 66.7 kg = 4.15 → 4.39 W/kg.** The goal wanted
316 W and FTP 300, so it missed by ~7 W on the test and ~6 on FTP — a good return
against a target that asked for +9%.

The **Aug 24 test is void**, and not a fitness failure: it broke at 14:30 on a side
stitch from a 45 g gel taken four minutes before the start. Its row and the Sep 1
row in `review/log.json` carry the full reasoning. **Never quote its 287.1 W as a
measurement** — that figure is an artifact of a 116-second hole, and the estimate
built from it (~283 W) undershot the real number by 10.6 W.

The shape was **two quality days a week on a deep Z2 base**: one threshold or
sweet-spot, one VO2, everything else easy enough to recover from them. The rider
already had a healthy top end (565 W for 1 min, 440 W for 8×1 min); the missing
stimulus was *accumulated time at and just below threshold*, so the block
progressed **time-in-zone before watts** — 48 min at 273 W Jul 30, 45 min at
275.6 W Aug 13, 55.5 min at 277.1 W Aug 17. That progression is what moved the
number, and the Aug 26 Limburg loop measured it independently on the same road as a
year earlier: **+17 to +28 W from 8 minutes upward, flat below 5** — exactly the
signature a threshold block should leave on a rider who was short only of
sustainable power.

**Two FTPs, and they are not interchangeable.** Every target in
`summer-training-plan.typ`, every row in `review/log.json` and every historical fuel
figure stands on **275**, and those constants are frozen there permanently. **293 is
the number for anything planned from 2 Sep onward.** See *Hold the FTP*.

Zones at **FTP 293**: **Z1 <164 · Z2 164–223 · Z3 223–267 · Z4 267–311 ·
Z5 311–354 · Z6 354–442 · Z7 >442 W.**
Zones at **FTP 275** (the summer block, for reading old rows): **Z1 <154 ·
Z2 154–209 · Z3 209–250 · Z4 250–292 · Z5 292–333 · Z6 333–415 · Z7 >415 W.**

The weeks, for reading old rows: 1 reset & test · 2–3 build · 4–5 Zeeland and the
Ospel crit · 6 peak load · 7 deload · 8 peak intensity · 9 final sharpening (Aug 17's
3×18min) · 10 taper, the void test, the Limburg loop, and the Sep 1 retest.

One constraint ran through every week and still does: the rider works **cinema
shifts** that log no TSS but cost a day on the feet, so sessions are fitted to the
roster, not the other way round.

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
  **How to Adjust**, twelve rules. `training-plan.typ` is its template
  (`week-table`, `workout-viewer`, `session-log`, `make-zones`).
- `workouts/workouts.json` — `ftp` (date-keyed, see below), `power_bounds`, 27
  structured `workouts` and 31 one-line `notes` (the easy/recovery/endurance days),
  keyed by ISO date. **Edit workouts here, never downstream.**
- `review/` — `log.json` holds only the two things an API cannot know: what was
  prescribed and the one-clause verdict. Everything objective is pulled.
- `nutrition/` — `fuel.py` builds daily kcal/carb targets from planned watts, the
  `work:` shift hours, and intervals.icu. It prescribes; it never sees intake.
- `docs/superpowers/` — design docs and implementation plans for the tooling.

# Pulling data

@NO_PULL_PARA@

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

**Never ask the rider for RPE or feel.** They are entered on the watch after every
structured workout and sync through with the activity — `icu_rpe` (1–10) and `feel`
(1–5, **1 strongest**) on `intervals-icu activity <id>`. They are *not* on the
`activities <days>` summary, which is why they look absent; that is the only reason
to reach for the full activity JSON on a normal review. `review/sessions.py` already
harvests both, so a session logged and re-run carries them without anyone being asked.

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

**Out of season this section is dormant — check the date before leaning on it.** It
was written for a July–August block where heat was the strongest single predictor of
whether a quality session landed, and every number in it comes from reps at
17.5–30.7 °C. Below ~20 °C none of the gates below bite and temperature is not a
candidate explanation for a bad session. The mechanics stay here because they are
sound and the block will come round again, not because they are currently live.

*Judge the heat during the reps* is the decision; this is how to read it. Use the
stream, not the summary field:

- `intervals-icu streams <id> temp` is a real per-second series, not a start-only
  value — Aug 1 2026 tracks 29 °C down to 20 °C across an evening.
- Average it **over the work intervals**, not the whole ride. The activity's
  `average_temp` can badly misrepresent them: Aug 1 averaged 23.5 °C while its first
  hour sat at 29 °C.
- Resolution is integer °C, and the sensor sits on the head unit, so it carries
  radiant and body heat. Reliable for comparing rides against each other; not a
  shaded air reading.

Worked comparison: Jul 30's 4×12 held 273 W at HR 163–165 with its reps at
**26.9 °C**; Aug 3's 2×15 at the same watts ran its reps at **30.7 °C**, hit HR 181,
and lost rep 2. Same rider, four days apart, same nominal freshness.

**Time of day is the lever, not the variable.** Jul 15 failed at 10:03 in 27.8 °C;
Jul 27's VO2 5×5 landed in full at 16:44 in 23 °C. Judge the temperature, then use
the clock to control it — start quality before 10:00 when the forecast tops 28 °C.

## `weather` — forecasting the window before the session

*Judge the heat during the reps* says check the forecast the evening before.
`weather` is the tool for it — Open-Meteo through a curl wrapper, no API key,
default location Beek en Donk (`-l eindhoven | helmond | <lat>,<lon>` to move it).

```
weather now                    weather day +1 [12-15]      hourly table
weather today [12-15]          weather window +1 12-15     summary over a window
```

`window` is the one to reach for: it collapses a candidate session window into
mean/range temperature, total rain, gusts and cloud — the fields the heat rule
actually turns on. Dates before today come from the ERA5 archive, today and later
from the forecast. **They are not interchangeable**: measured on Aug 13 2026 they
disagree by ~1.4 °C, more than the head-unit offset below, so never quote the
forecast endpoint's `past_days` for a ride that already happened.

**Air temperature predicts head-unit temperature almost directly.** The plan used
to assume the head unit read far higher because the sensor carries radiant load —
the Aug 13 cell predicted 26–31 °C against an air temperature of 20 °C. Measured
against `temp_work` in the session log the offset is small:

| | air over the reps | head unit | Δ |
|---|---|---|---|
| Aug 13, reps 08:30–09:25 | 20.0 °C | 20.5 | +0.5 |
| Aug 15, reps ~10:15–11:45 | 25.2 °C | 25.8 | +0.6 |

So a forecast reads almost straight against the heat rule's 26–28 / 28+ gates. Note
the `window` summary adds a flat **+1 °C**, so it prints about half a degree hot
against these two — err with it, not against it. Treat the nudge as an
approximation either way: two points, the head unit resolves to whole °C, and both
rep windows were inferred from the session structure rather than the streams. It is
not sharp enough to settle a call sitting on a gate — when one does, move the start
rather than split the difference.

Wind is worth a look on the same call: flat exposed roads plus gusts make a steady
275 W materially harder to hold, and it costs nothing to read it off the same table.

## Cronometer — what was actually eaten

Logged intake comes from the **`cronometer` MCP** (`mcp__cronometer__*`). The tool
descriptions say what each call does; they do not say the @CRON_COUNT@ things that matter.

@CRON_WRITE@- **Never score a day's intake before the day is over.** A diary pulled in the evening
  is a partial day, and reading it as a total turns unlogged dinner into a deficit. This
  has produced one wrong conclusion already: Aug 19 2026 was recorded at 17:02 as *1279
  kcal and 135 g carb short* with energy availability at a supposed ~19 kcal/kg FFM, and the
  full day actually came in at **4596 / 734 against a 4490 / 660 target — a surplus**.
  Pull the day the *following* morning. If a same-day pull is unavoidable, label it
  partial and do not draw a verdict from it.
- **`fuel.json` is the target, Cronometer is the outcome.** The comparison worth
  making is `get_daily_nutrition(date)` against `nutrition/fuel.json`'s `total_kcal`
  and `carb_g` for the same day. Nothing else closes that loop.
- **Ignore Cronometer's own target.** The rider eats to `fuel.py`'s numbers and does
  not look at Cronometer's — `total_target_kcal` is an artifact of Cronometer's model,
  not a target anyone follows. It cannot be made to agree, either: the MCP has no
  target-setting call, and Cronometer's only per-day mechanism is day-of-week macro
  templates, which cannot express a date-varying number. Its base is a flat figure
  against a plan whose daily target swings by well over 1000 kcal, so it will look
  plausible on an ordinary day and be badly wrong on the ones that matter. Never quote
  it, or its "remaining kcal", as a verdict.
- **`get_biometrics` is not a weigh-in log.** It is a carry-forward series: it
  returns the boundaries of whatever range you ask for with the last known value
  repeated. Two different windows both came back as two points at 65.2 kg. **Weight
  comes from `intervals-icu wellness`**, which hooks into Garmin directly and is what
  `fuel.py` reads; Cronometer's figure is hand-entered and goes stale.

Pull a day when the question turns on fuelling — a session that heat and TSB do not
explain, or the day before a headline session. Under-carbing before quality is a
real finding; one day's total on an easy week is noise.@CRON_TAIL@

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

### Pushing a test, specifically

Two details, both learned the expensive way on Aug 24:

- **A test is one workout step, not three.** Garmin makes every step its own lap, so
  a single 20-minute step means **the lap average is the test score, live, for the
  whole twenty minutes** — which is the number to steer by. A 12/6/2 ramp resets that
  average twice and leaves the rider pacing blind. The opening band and the lift at
  minute 12 belong in the step *note* and in the plan cell, not in the step structure.
- **Check the watts actually reach the watch.** `garmin/transform.py` listed `test` in
  `OPEN_POWER_KINDS`, which strips the alert band off every explicit-power step on the
  theory that a test is ridden all-out by feel. `workouts.json` carried an explicit
  310 W and it was deleted in transit, so Aug 24 was ridden off the lap screen with no
  target displayed. **Fixed 28 Aug**, `test` is out of that list, and there is a
  regression test. The general lesson is that a silent transform between the plan and
  the head unit can delete the one number the session exists to hold.

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

**The FTP constants are date-keyed, and the summer block's is frozen.** Both
`workouts.json` and `review/log.json` carry an `ftp` that is read *retroactively* —
`log.json`'s drives the `0.85 × FTP` threshold deciding which seconds count as "work"
for every historical rep temperature, and `workouts.json`'s prices every past day's
planned fuel target. A scalar bump from 275 to 293 would therefore have re-cut
`temp_work` for every session in the evidence base and inflated every historical fuel
figure. Both files now take a **list of `{"from": "<ISO date>", "ftp": <W>}` bands**
instead (a bare number still works and means "this FTP for all dates"). **275 runs to
2026-09-01 and must not be edited**; 293 starts 2026-09-02. Add a band, never change
one that has dates behind it.

# The rules this block earned

The plan's `How to Adjust` carries all twelve under these names. **Cite a rule by
name, never by number** — the list has been inserted into four times, so the numbers
have moved and a stale "rule 7" now points at the wrong rule. The ones that change
decisions most:

- **Nothing hypertonic inside 15 minutes of hard work.** The rule that cost this
  block its headline test. A 45 g gel inside 20 minutes of a maximal effort produced
  a ~2-minute stoppage on **Aug 15** and again on **Aug 24** — same dose class, same
  failure mode, nine days apart. At test intensity splanchnic flow drops 60–80% and
  gastric emptying effectively halts, so the bolus is still in the stomach at minute
  15. Sep 1 was ridden clean and it did not recur. Breakfast already puts the fuel on
  board; there is no problem to solve inside twenty minutes. If a stitch starts
  anyway, **do not stop dead** — drop to ~200 W and force the exhale on the leading
  leg's downstroke. That costs 30 s, not 116.
- **Set the target from the evidence, not from the goal.** Aug 24's "310 W anchor"
  was reverse-engineered from the 316 W needed for FTP 300, not from anything in the
  record — Jun 30 had opened at 285 and negative-split. The rider rode 306 to brief,
  shed power from minute 10, and broke. Sep 1 replaced it with an openable band and a
  lift at minute 12: opened 299, sat 300–307 to minute 11, lifted, and negative-split
  to 321. **Same protocol, nine days apart, +21.9 W.** Quarters are the proof —
  Aug 24 ran 303.9 / 305.3 / 271.9 / 267.3; Sep 1 ran 299.6 / 305.9 / 313.0 / 317.3.
  This is a rule about how *the plan writes numbers*, and the failure mode is the
  plan's, not the rider's.
- **Hold the FTP.** **275 is frozen** — it is what every summer-block target, log row
  and historical fuel figure is computed against, and moving it would silently
  rewrite the record. **293 is live from 2 Sep.** Targets are ridden as ceilings you
  are allowed to beat, noted rather than rescaled; a test moves the number, a good
  session does not. **Never rescale off a hot session**, and never off a session with
  a hole in it — the Aug 24 substitution estimate undershot by 10.6 W, because
  replacing a stoppage with the power shown after it is conservative, not neutral.
- **Trust feel; ignore RPE.** Feel runs 1–5 with **1 strongest**. Across the whole
  block feel marked exactly **three** sessions 1 — Aug 13, Aug 17 and Sep 1 — and
  those are **the three best sessions in the log**. Nothing else in the record
  separates them: not RPE, not TSB, not HRV, not sleep. RPE read **10 on both the
  void test and the best twenty minutes on record**; it is a default, not a signal.
  The rider's free-text note is worth more than either.
- **Chronic freshness reads; acute readiness doesn't.** The two tests bracket this
  from opposite ends. **Aug 24**: TSB +3.2, HRV 58, RHR 49, 8 h 35 sleep — the best
  acute markers of the week, and it broke. **Sep 1**: TSB +7.6 (the freshest morning
  in the entire log), HRV 42, RHR 56, 5.9 h sleep after a 03:00 bedtime — the *worst*
  acute markers of the week, and the best twenty minutes on record. Aug 13 (−8.9),
  Aug 17 (−8.4) and Aug 20 (−13.8) are three of the block's best sessions at negative
  TSB. **Do not gate a test or a race on morning HRV/RHR/sleep score** — record it and
  ride.

  *The rider's standing caveat, and it is not yet tested:* a
  suppressed HRV probably does deserve more weight **week on week in training** than
  on a single hard day — but only when bedtime and sleep duration were normal and
  **nothing else explains the suppression** (a late shift, a party, heat, a big day
  before). This block only ever tested the single-day case, and refuted it there.
  Nothing in the log speaks to the week-on-week case either way. Treat it as the
  rider's hunch, worth acting on cautiously and worth actually testing — the read
  would be a run of unexplained low-HRV mornings against what the following week's
  quality sessions deliver.
- **Time-in-zone before watts.** Raise total work, then rep length, then watts.
  Prefer 5×4 over 4×5, 4×12 over 3×16. This is what moved the number: 48 min at
  273 W → 45 at 275.6 → 55.5 at 277.1, and then +20 W on the test.
- **Progress the total, not the target.** Long reps need a number, not feel: every
  long-rep session that broke did so because rep 1 drifted up; the two that went
  cleanly were ridden to a hard ceiling.
- **Watts are the guardrail.** An endurance day has a target, not a ceiling:
  155–200 W *held*. Z1 transport and commutes are recovery — real, worth keeping,
  and **not** the endurance day. Budgeting them as one is the error that cost this
  block its aerobic base in Weeks 5–7 (22 min of Z2 on Jul 29 against 135 min on
  Aug 11). Read HR for drift (>~8 bpm at the same power = the ride changed).
- **Fit quality to the work calendar.** Hard sessions on a free day, or on a work
  day *before* an evening shift. All-day shifts stay easy or rest. Never a hard
  session the day before a day that cannot absorb it.
- **Judge the heat during the reps.** Heat is the variable; the clock is only the
  lever. Judge temperature *during the reps*, not the day's peak — ~8 bpm separates
  27 °C from 30 °C at the same watts, which looks exactly like under-recovery.
  26–28 °C, consider moving the start; 28 °C+, change course. *This rule dominated a
  July–August block and is dormant out of season* — reps ran 26.9–30.7 °C through the
  build against 17.5–22.9 °C from Aug 13 on, and heat was not in play in either test.
  It stays here because the mechanism and the numbers are sound, not because it is
  currently the live constraint.

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

1. Read the plan's **Overview & Principles** and **How to Adjust**, plus the **week
   table covering whatever day is being asked about**. The file is large; grep for
   the week heading rather than reading all 480 lines.
2. Read `review/sessions.json` for what the block actually delivered.

The block closed on 1 Sep 2026, so there is no "current week" in this plan any more.
A question about *today* is about what comes next, not about a cell in this
document — answer it from the rules and the log, and say plainly that the plan
itself ends on Sep 1.

@TASK_INPUT@

- **Asks for data** — "pull the last 3 days", or a claim only the API can settle:
  fetch, then review against the current week. Did quality sessions match their
  targets in watts, duration and reps (temperature over the reps before blaming
  fitness or fatigue)? Easy days actually easy, IF below ~0.75? Volume vs plan?
- **Asks a question** — answer it from the plan and the session log, citing the
  rows and rules it turns on. Pull data only if the question needs it.
- **Carries notes on a session** — record them as a prescribed/delivered/verdict
  row for `review/log.json`, not as prose.
- @EMPTY_CASE@ where things stand in a few lines. What the
  block finished at, anything stale or unresolved, and what the next decision is.
  Pull nothing, then stop and wait.

No status-report preamble. Say plainly when the evidence doesn't settle it. Flag
what the plan should change with its reasoning — **propose changes, don't make
them.** Nothing gets edited or pushed until the rider says so.
