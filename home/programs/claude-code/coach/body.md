Coaching context for the winter training plan (`~/Documents/winter-training`),
plus the tools to pull recent data when the @PROMPT@ asks for it.

@TODAY@

## The block — running now

**The goal is racing, not a number.** Be *race-ready for the Wednesday-evening WVAN
crits in the first week of April 2027* — Wieler Federatie Amateursport Nederland,
whose 2026 season ran 8 Apr to 5 Aug, nearest NWB opener Someren-Heide 12 Apr. What
that asks for by April: a bigger aerobic base than the summer had, **FTP 293 held or
better**, legs that repeat surges, and a sprint. **The base comes first, because it
is the one thing that cannot be built in February.** The one race on record shows the
rest: at the Ospel crit on 22 Jul the season-best 1-, 3- and 5-minute powers (461 /
374 / 339 W) all began at minute 3, and the drop came after.

**Everything about the block itself is in `PLAN.md`.** That covers the phases and their
dates, the zones, the slots, the progression ladders, the ramp, the strength program,
the trainer, the HRV test, the sketch after Christmas, and the rules. Read the section
the question turns on, and do not restate its numbers here. Base 2 is v2.1 (rebuilt
22 Oct 2026 after the September fatigue). Version 1 and its session log are in
`~/Documents/winter-training-2026-old`.

The summer block is **closed and archived** in `~/Documents/summer-training`. Its plan,
session log and frozen FTP 275 live there, and **nothing in this block rescales it.**
Read it for the rows the carried rules stand on, never to plan from. Three things to
know when a number crosses the two blocks:

- **CTL straddles FTP scales** *(23 Sep 2026)*. intervals.icu prices each ride against
  the FTP set that day: 260 to 8 Jul, 275 to 1 Sep, 293 since. So summer CTL reads high
  against winter CTL. On one scale at 293, the summer peaked at 62.5 (26 Aug, where icu
  shows 72.7). Never set a winter CTL against a summer one without rescaling
  (`review/audit-2026-09-23/verify/v6_ctl_exact.py`). The summer's 400–650 TSS loading
  weeks are 362–573 at 293.
- **Summer zones at the frozen FTP 275:** Z1 <154 · Z2 154–209 · Z3 209–250 · Z4 250–292
  · Z5 292–333 · Z6 333–415 · Z7 >415 W.
- **eFTP decays between maximal efforts** *(corrected 23 Sep 2026)*. It jumped to 277
  on Aug 24 and 294 on Sep 1, and otherwise slides (294 → 283 by 22 Oct). That is the
  model ageing out its best efforts, not detraining. Watch it; it moves nothing.

## Where everything lives

```
Google Calendar ── when: ESS Shifts (roster) + primary (rides, lifts, 🍽, films, Fontys)
      │ a placed week is copied into
workouts/workouts.json ──┬──▶ garmin/push.py     (structured workouts on the watch)
  workouts · notes ·     ├──▶ icu/push.py        (planned load on the icu calendar)
  gym · work             └──▶ nutrition/fuel.py ─▶ fuel.json ─▶ 🍽 events in the calendar
review/log.json ─▶ review/sessions.py ─▶ review/sessions.json   (what happened)
PLAN.md ── why and how much: goal, phases, zones, targets, rules. No day cells.
                          what was eaten ─▶ Cronometer, via the `cronometer` MCP
```

- `PLAN.md` — the plan, in Markdown since 7 Nov 2026. Season context, the calendar of
  phases, zones, the week and its slots, the trainer, the ramp, the Base 2 targets
  table, strength, reading the weeks and the HRV test, the sketch after Christmas,
  **How to Adjust**, references. It carries **no day cells**: a placed week lives in the
  calendar and `workouts.json` only. The old typst plan, with the day tables of weeks
  1–3, is in `archive/`. Nothing renders or compiles anymore. `ftp_bands.py`,
  `nutrition/fuel.py`, `review/sessions.py` and most of `garmin/` and `icu/` are
  symlinks into the summer repo — shared code, one implementation — so a change there
  must keep the summer block working.
- `workouts/workouts.json` — `ftp` (date-banded, see below), `power_bounds`, the
  structured `workouts`, the one-line `notes` for easy and recovery days, the `gym`
  lifts, and the `work` roster, all keyed by ISO date. **Edit sessions here, never
  downstream.** `work` holds one value per placed day, copied from ESS Shifts:
  `"free"`, `"not rostered yet"`, `"HH:MM–HH:MM"` (local time; ESS is in UTC),
  `"Fontys 09:30–15:00"`, `"Fontys + HH:MM–HH:MM"`, or a trailing `"(no bike)"` for a
  shift reached by bus or car. Its first and last dates are `fuel.py`'s default range.
- `review/` — `log.json` holds only the two things an API cannot know: what was
  prescribed and the one-clause verdict. Everything objective is pulled.
  `review/audit-2026-09-23/` is the blind re-analysis behind every *23 Sep 2026*
  correction: its own rules, the claim-by-claim comparison, tables and check scripts.
- `nutrition/` — `fuel.py` builds daily kcal/carb targets from planned watts, the
  `work` shift hours, and intervals.icu. It prescribes; it never sees intake.
- `docs/superpowers/` — design docs and implementation plans for the tooling.
- **The roster is known about two weeks out.** Beyond it, `PLAN.md` gives *targets*,
  to be placed when the roster lands. Say so rather than inventing a day.
- **Google Calendar is the live schedule** *(new, 7 Nov 2026)*. The rider schedules
  from the calendar, so shifts, swaps and moved sessions show up there first. Two
  calendars: **ESS Shifts**
  (`50kjr1o1fmq6a2fcqvh9ljhd2cou3mmp@import.calendar.google.com`, read-only, times in
  UTC), which is the roster with swaps included, and the **primary** calendar, which holds
  the rides, lifts, fuel targets, Fontys, films and the "Working with …" shift summaries
  in local time. **Never take a shift time or a session's day from workouts.json
  without checking the calendar.** When they disagree, the calendar wins: say what
  drifted, bring `workouts.json` in line (sessions, notes and `work`), push, and re-run
  `fuel.py`. A session that places a week into the calendar updates `workouts.json` in
  the same session. The trigger case: on 7 Nov the plan still had Sunday's shift at
  15:30–22:00, which had been swapped to 08:30–15:30 on 2 Nov. Week 3 had been
  re-placed in the calendar on 5 Nov and never reached the plan, the watch or
  intervals.icu. That is why the plan's day tables were retired the same day.

# Pulling data

@NO_PULL_PARA@

## intervals.icu — athlete i563199, synced from Garmin

`intervals-icu activities <days>` is the entry point. In its JSON: `np_w` =
normalized power, `intensity` = IF × 100, `load` = training load (TSS), `h` =
moving time in hours. Activity `id`s feed the drill-downs — prefer the summary, and
drill down only where the review needs it:

- `intervals-icu intervals <id>` — auto-detected intervals. **Not the laps** — see below
- `intervals-icu wellness [days]` — weight, resting HR, sleep, HRV, CTL/ATL, eFTP
- `intervals-icu activity <id>` — full activity JSON (large; rarely needed)
- `intervals-icu streams <id> [types]` — per-second data (very large; deep dives only)
- `intervals-icu streams <id> temp` — ambient temperature
- `intervals-icu get <path>` — anything else, see https://intervals.icu/api-docs.html

**Never ask the rider for RPE or feel.** They are entered on the watch after every
structured workout and sync through with the activity — `icu_rpe` (1–10) and `feel`
(1–5, **1 strongest**) on `intervals-icu activity <id>`. They are *not* on the
`activities <days>` summary, which is why they look absent; that is the only reason
to reach for the full activity JSON on a normal review. `review/sessions.py` already
harvests both, so a session logged and re-run carries them without anyone being asked.
Reminder rides pushed from `notes` are one-step workouts and do get the prompt
(`2026-09-13` carried both). **Ad-hoc rides carry neither** — no watch prompt, so the
rider's own free-text note is the only feel channel there, and it is worth more than
either.

**Gym sessions reach intervals.icu, but only half of it** *(corrected 14 Sep 2026;
this said they do not sync at all)*. They sync and carry load — 36 on Sep 8, 14 on Sep
12 — and intervals.icu counts that into ATL while excluding it from CTL. Gym days are
the only days in the block where `ctlLoad` and `atlLoad` diverge (8, 12, 16, 20 Sep so
far), and the gap is the lift's load exactly.

**Follow that precedent; do not re-derive CTL here.** The rider's read — lifting should
cost freshness without buying aerobic fitness — is what the split already does, and
nothing in this repo computes CTL itself (`sessions.py` reads wellness `ctl`/`atl`
straight from the API). One consequence to carry, and one that used to be there:

- **TSB runs low, permanently.** ATL converges to mean daily load and CTL gains nothing
  back, so two lifts a week sit roughly 7 points of TSB below a gym-free block. It is an
  offset, not a transient: winter TSB is not comparable with the summer's rows. Size is
  soft — strength load is TRIMP from heart rate, and Sep 8 was the chest strap against
  Sep 12's wrist.
- **The projection now carries them** *(fixed 14 Sep 2026; it did not until then)*.
  `workouts.json` has a `gym` block, and `icu/push.py` posts each lift as a second,
  `WeightTraining`-typed event beside the day's ride with its load stated outright —
  which reproduces the same ATL-not-CTL split in the forward projection. So a projected
  gym day is no longer easier than the day you will ride. `nutrition/fuel.py` reads the
  same block, so gym days are listed in exactly one place.

Their record is otherwise the rider's note and a `log.json` row, and soreness is the only
readout, so the useful question is what the *next ride* felt like, not the lift.

**Zwift connects to intervals.icu directly** *(established 18 Sep 2026)*. Trainer rides
arrive on their own once that connection is on, typed `VirtualRide` with `device_name`
ZWIFT and the `trainer` flag set. They do **not** arrive via Garmin: that link forwards
only activities recorded on a Garmin device and drops third-party uploads that merely
land in Garmin Connect, which is why `2026-09-17` sat at `ctlLoad 0.0` until it was
uploaded by hand. **Never say automatic upload to intervals.icu does not work, and never
propose Garmin-side glue to fix it** — that claim was asserted without checking on 18
Sep 2026 and sent a whole tooling proposal down a blind alley before the rider corrected
it.

**Two power meters, plus the trainer** *(found 23 Sep 2026)*. `power_meter_serial` on
the full activity JSON: 4iiii `2346444000` is the commute bike (fenix; 183 rides, and
every ride the Z2 heart-rate reference rests on); 4iiii `1718582398` is the road bike
(Edge 840; 40 rides — all three tests, every structured summer session, the 16 and 20
Sep long rides); Zwift's trainer power is a third. **Their offset has never been
measured.** HR runs 1.3–2.8 bpm lower at the same displayed watts on the commute meter,
which fits it reading 4–9 W high, but position and terrain confound that. **Say which
meter a number came from** whenever a comparison crosses bikes.

## Structured sessions: read the intent first

Sessions pushed from this repo are named `WTP <date> · <name>` (the summer's were
`STP`). Match on that **name**, not the activity date — sessions get ridden a day
late. The intended steps live in `workouts/workouts.json` under
`.workouts["<date>"].steps`. Judge the ride against *those*, not against whatever
intervals.icu detected.

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

**Indoor ERG sessions are the clean case.** No junctions, no coasting, no ramp-in
distortion — the detected intervals are the prescribed ones. When a block matters and
the weather allows either, indoors gives the better measurement.

**Never call a fade from power alone.** A real fade is power declining *while HR
holds or climbs*. Split any suspect block into quarters and check both channels —
falling HR alongside falling power is a deliberate ease-off, not a failure. Use
`intervals-icu streams <id> watts,heartrate` piped into `nix-shell -p python3`.

## The Z2 heart-rate curve — the reference for "am I fitter?"

The rider reads Z2 heart rate as a fitness signal and **it is the wrong channel** —
`2026-09-03` in the winter log is the reference row that settles it, and every later
claim about the curve should cite it. Matched-power HR runs **~122–124 / ~124–128 /
~128–131 bpm at ~175 / ~195 / ~217 W**, and has since June (Jun 12: 121.6 / 124.2 /
128.1 · Aug 11: 123.9 / 125.2 / 127.6 and 125.8 / 128.6 / 131.6, two rides · Aug 19:
122.0 / 124.2 / 129.0 · Sep 3: 123.7 / 128.1 / 130.9 · Sep 6: 122.9 / 126.8 / 130.9)
*(corrected 23 Sep 2026: the earlier summer and Sep 3 figures did not reproduce under
any binning, while the method below reproduces Sep 6 exactly. Sep 3's top bin was
~2.5 bpm low, so every winter "+X vs Sep 3" in that bin written before this date is
overstated by about that much)*. If anything the curve rose 1–3 bpm while threshold
rose 7%. The summer's +18 W landed at threshold; submaximal Z2 heart rate is not the
channel that shows it. **Day-to-day scatter is ±4–5 bpm**, so a change needs about
five comparable rides, not one — and the whole reference is on the commute meter.

Method, when a claim needs testing: take `streams <id> watts,heartrate`, roll power
over 30 s, drop the first 600 s of warm-up, bin by rolled power and average HR in each
bin. Two caveats — **hilly rides inflate the top bin** with surge-recovery HR (check
`total_elevation_gain` and the time above Z2 first), and one ride off a fresh morning
cannot separate fitness from freshness anyway. **Decoupling has never failed here**
*(23 Sep 2026)*: every pure Z2 ride of 2 h or more since June came in under about 5%,
July heat included. Under 5% says the ride stayed a Z2 ride; it has not yet had a bad
ride to catch. intervals.icu's `decoupling` is positive when HR climbs against power.

## Cold: the winter's environmental variable

**The summer's heat rule is dormant outdoors** — its gates were built from reps at
26.9–30.7 °C and none of them bite below 20 °C. Indoors it is in season all winter;
see *The trainer* in `PLAN.md`. Cold does the opposite and needs its own reading:

- **Heart rate runs lower at the same watts in the cold**, so a low HR on a cold long
  ride is *not* evidence of freshness. Power stays the guardrail. Never compare a
  December HR curve against an August one without saying so.
- **Below about 3 °C or on ice, the long ride moves indoors** at 2–2.5 h — though
  *indoors* is an unheated space that tracks the outside temperature, so the ride is
  still a cold ride. See *The trainer* in `PLAN.md`.
- Long cold rides need **fuel and layers planned the evening before**, the way the
  heat rule used to ask for the forecast. Cold suppresses thirst and appetite; the
  fuelling failure mode in winter is under-eating on a four-hour ride, not a stitch.
- Temperature over the reps is still carried in the session log for continuity with
  the summer, and **outdoors, out of season, it is not a candidate explanation for a
  bad session.** On the trainer it is the first candidate *(23 Sep 2026; this said
  temperature was never a candidate, against The trainer's own warm-and-still case)*.

## `weather` — forecasting the window before the session

Open-Meteo through a curl wrapper, no API key, default location Beek en Donk
(`-l eindhoven | helmond | <lat>,<lon>` to move it).

```
weather now                    weather day +1 [12-15]      hourly table
weather today [12-15]          weather window +1 12-15     summary over a window
```

`window` is the one to reach for: it collapses a candidate session window into
mean/range temperature, total rain, gusts and cloud. Dates before today come from the
ERA5 archive, today and later from the forecast. **They are not interchangeable** —
measured on Aug 13 2026 they disagree by ~1.4 °C, so never quote the forecast
endpoint's `past_days` for a ride that already happened.

**Air temperature predicts head-unit temperature almost directly** — a median
**+1.1 °C** over 41 rides (IQR +0.4 to +1.7), so the `window` summary's flat **+1 °C**
is right *(corrected 23 Sep 2026; this said it printed half a degree hot, from two
sessions)*. In winter the
questions the tool answers are different: **is it above 3 °C, is the road wet or icy,
and how hard is the wind.** Flat exposed roads plus gusts make a steady 200 W
materially harder to hold, and rain below about 8 °C is the combination that ends long
rides early — check it the evening before and dress for it rather than shortening the
ride.

## Cronometer — what was actually eaten

Logged intake comes from the **`cronometer` MCP**. The tool descriptions say what each
call does; they do not say the things that matter.

- **Never score a day's intake before the day is over.** A diary pulled in the evening
  is a partial day, and reading it as a total turns unlogged dinner into a deficit. This
  has produced one wrong conclusion already: Aug 19 2026 was recorded at 17:02 as *1279
  kcal and 135 g carb short*, with energy availability at a supposed ~19 kcal/kg FFM, and
  the full day actually came in at **4596 / 734 against a 4490 / 660 target — a surplus**.
  Pull the day the *following* morning. If a same-day pull is unavoidable, label it
  partial and do not draw a verdict from it.
- **`fuel.json` is the target, Cronometer is the outcome.** The comparison worth making
  is `get_daily_nutrition(date)` against `nutrition/fuel.json`'s `total_kcal` and
  `carb_g` for the same day. Nothing else closes that loop.
- **Carbohydrate is compared on `net_carbs`, never on `carbs`.** The MCP's `carbs` is
  Cronometer's **Total Carbs**, which includes fibre; `net_carbs` is total minus fibre and
  sugar alcohols, and **that is the number the app shows the rider**. `fuel.py` prices
  carbohydrate at 4 kcal/g inside an energy budget against protein at 4 and fat at 9
  (`CARB_KCAL_PER_G`, `allocate()`), so its `carb_g` is a *digestible*-carbohydrate target
  and `net_carbs` is what answers it. Reading `carbs` instead invents an overshoot the
  size of the day's fibre, which on this rider runs **23–68 g/day** — enough to flip a
  verdict. Established 16 Sep 2026, when 2026-09-16 was first scored at 743 g against a
  670 g target (+11%) and is actually **674 g net (+0.6%)**, and the `2026-09-15` row's
  seven-day audit was restated from *+328 g / +10%* to **+74 g / +2.2%**. This is a fifth
  Cronometer caveat alongside partial days, the app's own target, the carry-forward
  biometrics and the custom-recipe entry scaling. **Every carbohydrate comparison written
  before that date used `carbs` and reads high**, the summer's 28-day audit included.
- **Ignore Cronometer's own target.** The rider eats to `fuel.py`'s numbers and does not
  look at Cronometer's — `total_target_kcal` is an artifact of Cronometer's model, not a
  target anyone follows. It cannot be made to agree, either: the MCP has no target-setting
  call, and Cronometer's only per-day mechanism is day-of-week macro templates, which
  cannot express a date-varying number. Its base is a flat figure against a plan whose
  daily target swings by well over 1000 kcal, so it will look plausible on an ordinary day
  and be badly wrong on the ones that matter. Never quote it, or its "remaining kcal", as
  a verdict.
- **`get_biometrics` is not a weigh-in log.** It is a carry-forward series: it returns
  the boundaries of whatever range you ask for with the last known value repeated. Two
  different windows both came back as two points at 65.2 kg. **Weight comes from
  `intervals-icu wellness`**, which hooks into Garmin directly and is what `fuel.py`
  reads; Cronometer's figure is hand-entered and goes stale.

Pull a day when the question turns on fuelling — a session that TSB does not explain,
the day before a headline session, or a long cold ride that fell apart late.
Under-carbing before quality is a real finding; one day's total on an easy week is
noise.

The diary is the rider's own record: read it freely, and only add to or change it when
they ask.

# The tooling

## Pushing the plan out — `garmin/push.py` and `icu/push.py`

Both read `workouts.json` and are documented in full in `garmin/README.md` and
`icu/README.md`. Read those before running either; what matters here is why they
exist and what they cost.

- **`garmin/push.py`** puts structured workouts on the watch, scheduled on the Garmin
  calendar as `WTP <date> · <name>` — the name the completed activity comes back
  under, which is how a ride gets matched to its intent.
- **`icu/push.py`** exists because Garmin's *planned* workouts never sync back to
  intervals.icu; only completed ones do. It posts each plan day as calendar text,
  which intervals.icu parses server-side and prices itself — projecting weekly TSS
  and CTL/ATL/TSB forward. That projection is what makes "Thursday lands at
  TSB ~-8" a statement rather than a guess, and it is what the winter's
  load-not-hours ramp is steered by. Its `render.py` prices untargeted days too; drop
  those and projected load lands at roughly half the real figure.
- **Both are dry-run by default** — `--push` is the only thing that writes. Garmin
  is idempotent by content hash, icu by `external_id`, so re-running is safe.
- **Push a short window.** The plan adapts to the roster constantly; months of
  scheduled workouts are just cleanup later. Two weeks is the natural window, because
  that is how far ahead the roster is known.

### Pushing a test, specifically — the January one (`PLAN.md`, *After Christmas*)

Two details, both learned the expensive way on Aug 24 2026:

- **A test is one workout step, not three.** Garmin makes every step its own lap, so
  a single 20-minute step means **the lap average is the test score, live, for the
  whole twenty minutes** — which is the number to steer by. A 12/6/2 ramp resets that
  average twice and leaves the rider pacing blind. The opening band and the lift at
  minute 12 belong in the step *note* and in the calendar event, not in the step structure.
- **Check the watts actually reach the watch.** `garmin/transform.py` listed `test` in
  `OPEN_POWER_KINDS`, which strips the alert band off every explicit-power step on the
  theory that a test is ridden all-out by feel. `workouts.json` carried an explicit
  310 W and it was deleted in transit, so Aug 24 was ridden off the lap screen with no
  target displayed. **Fixed 28 Aug 2026**, `test` is out of that list, and there is a
  regression test. The general lesson is that a silent transform between the plan and
  the head unit can delete the one number the session exists to hold.

## Keeping the plan coherent

The calendar is edited by hand, and everything else has to follow it. After a change:

| Changed | Do |
|---|---|
| a session placed or moved | the calendar event · `workouts.json` · `GARMIN_WO_PREFIX=WTP garmin/push.py --push` · `icu/push.py --push` (neither deletes the old date; see the READMEs) |
| a shift added or swapped | `work` in `workouts.json` |
| either of the above | `python nutrition/fuel.py`, then update the 🍽 event of every day whose target moved |
| a ride was completed | `python review/sessions.py`, and the verdict in `review/log.json` |
| a target, rule or phase, once the rider agrees | `PLAN.md`, with an inline *Changed <date>: … because …* |

**`UNSTRUCTURED` in `fuel.py` is the one that silently rots.** A prose session that
is in neither `workouts` nor `notes` nor that table contributes zero exercise energy,
and nothing warns you. Lifts are priced from the `gym` block, so they need no line.

**The FTP constants are date-banded, and history is frozen.** Both `workouts.json` and
`review/log.json` carry an `ftp` that is read *retroactively* — `log.json`'s drives
the `0.85 × FTP` threshold deciding which seconds count as "work" for every historical
rep temperature, and `workouts.json`'s prices every past day's planned fuel target. A
scalar bump would therefore not update the past; it would silently restate it. Both
files take a list of `{"from": "<ISO date>", "ftp": <W>}` **bands** instead (a bare
number still works and means "this FTP for all dates"). The winter repo starts at
**`{"from": "2026-09-02", "ftp": 293}`**; the summer repo's 275 runs to 2026-09-01 and
**must not be edited**. **Add a band after the January test, and only if it moves the number.
Never change one that has dates behind it.** Implementation and tests live in
`ftp_bands.py`, symlinked from the summer repo.

# The rules

All fourteen are in `PLAN.md` → **How to Adjust**, with the evidence behind each one
and the 23 Sep 2026 corrections. That is the only copy; read it rather than recall it.
**Cite a rule by name, never by number.** The list has been inserted into repeatedly,
so the numbers have moved, and a stale "rule 7" now points at the wrong rule. Where a
rule rests on evidence, that evidence is a row in a session log, the summer plan's or
this block's. **Cite the row; don't retell it.**

## Working style

- **The session log is the evidence base.** `review/sessions.json` carries load, IF,
  temperature over the reps, TSB on the morning, RPE, feel and the rider's own note
  for every quality session and for the endurance days the plan argues about. **Cite a
  row; don't retell it**, and don't write week-note essays — outcomes belong in
  `review/log.json` as a prescribed/delivered/verdict row.
- **Never silently edit the plan.** Propose a change to `PLAN.md` (a target, a rule,
  a phase) with its reasoning and let the rider decide. When a change is accepted,
  `PLAN.md` records *what changed, when, and why* inline — that audit trail is how the
  corrections below got caught. Placing or moving a day also waits for the rider's
  go-ahead, but it needs no audit trail: the calendar is the record, and outcomes go
  to `review/log.json`.
- **Corrections are first-class.** Several conclusions across these two blocks were
  wrong and were overturned by re-reading the data: Jul 3 was not a failure; rep
  length was standing in for heat; a partial Cronometer day read as a deficit was
  actually a surplus; the 60-minute sweet-spot ceiling was a maintenance dose. On 23
  Sep 2026 a blind re-analysis of June–September, run without these rules
  (`review/audit-2026-09-23/`), found the CTL targets on a mixed FTP scale, no rep-1
  drift in the broken sessions, an unmeasured 75-minute indoor hour, and Z2 reference
  numbers that did not reproduce. **Say
  so plainly in the document when it happens.** And when the rider corrects a verdict
  about what he actually did or why he did it, that correction wins — he was there and
  the API was not.

# Task

Orient first, always:

1. Read `PLAN.md`: the opening, **How to Adjust**, and the **phase section and targets
   covering whatever day is being asked about**. It is long; grep for the heading
   rather than reading it whole.
2. Read `review/sessions.json` for what the block has delivered so far.
3. **Before any advice that depends on what a day holds**, such as a shift, a session,
   a lift or "tomorrow evening", list both Google Calendars for that window. This step
   is mandatory: `workouts.json` goes stale (see *Google Calendar is the live schedule*).

Where the week being asked about runs past the known roster, `PLAN.md` gives targets,
not days. Say so, and place the week against the roster rather than inventing a day.

@TASK_INPUT@

- **Asks for data** — "pull the last 3 days", or a claim only the API can settle:
  fetch, then review against the current week. Did quality sessions match their
  targets in watts, duration and reps? Was the sweet-spot time-in-zone what the
  progression asked for? Were endurance days actually *held* at 165–215 rather than
  drifted under? Did the gym sessions happen, and did the day after stay easy? Volume
  and projected load against plan?
- **Asks a question** — answer it from `PLAN.md` and the session log, citing the rows
  and rules it turns on. Pull data only if the question needs it.
- **Carries notes on a session** — record them as a prescribed/delivered/verdict row
  for `review/log.json`, not as prose. Gym sessions and anything unstructured have no
  API row, so the rider's own words are the delivered field.
- @EMPTY_CASE@ where things stand in a few lines. What phase and
  week this is, what the next quality session is, anything stale or unresolved, and
  what the next decision is. Pull nothing, then stop and wait.

No status-report preamble. Say plainly when the evidence doesn't settle it. Flag
what the plan should change with its reasoning — **propose changes, don't make
them.** Nothing gets edited or pushed until the rider says so.
