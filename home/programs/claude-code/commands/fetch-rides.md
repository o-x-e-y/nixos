---
description: Pull recent rides from intervals.icu and review them against the summer training plan
argument-hint: [days]
allowed-tools: Bash(intervals-icu:*), Bash(nix-shell:*), Read, Grep, Glob
---

Review recent training data from intervals.icu (athlete i563199, synced from Garmin).

## Context

Recent activities: !`intervals-icu activities $ARGUMENTS`

## Field glossary

In the JSON above: `np_w` = normalized power, `intensity` = intensity factor (IF × 100),
`load` = training load (TSS), `h` = moving time in hours. Activity `id`s feed the
drill-down commands below.

## Drill-down commands

Prefer the summary above; drill down only where the review needs it:

- `intervals-icu intervals <id>` — auto-detected intervals. **Not your laps** — read the caveats below before trusting the structure
- `intervals-icu wellness [days]` — weight, resting HR, sleep, HRV
- `intervals-icu activity <id>` — full activity JSON (large; rarely needed)
- `intervals-icu streams <id> [types]` — per-second data (very large; only for deep dives)
- `intervals-icu streams <id> temp` — ambient temperature; see the heat section below, and pull
  it for **every** quality session before drawing conclusions from HR
- `intervals-icu get <path>` — anything else, see https://intervals.icu/api-docs.html

## Structured sessions: read the intent first

Sessions pushed from this repo are named `STP <date> · <name>`. Match on that **name**, not
the activity date — sessions get ridden a day late. The intended steps live in
`~/Documents/summer-training/workouts/workouts.json` under `.workouts["<date>"].steps`. Read
them and judge the ride against *those*, not against whatever intervals.icu detected.

`intervals-icu intervals <id>` returns auto-detected intervals. On outdoor rides it distorts
sessions in two known ways:

- **It splits reps at junctions.** Brief coasting becomes a 6–20 s `RECOVERY`, turning three
  reps into eight fragments. Merge `WORK` intervals separated by gaps under ~30 s before
  reading anything into the structure.
- **It charges rep ramp-ups to the preceding recovery.** A `WORK` interval doesn't open until
  power stabilises, so the ramp-in inflates the recovery's average watts and shortens the rep.

intervals.icu knows the true lap count (`icu_lap_count` on the activity) but exposes no laps
endpoint — `/activity/<id>/laps` 404s. The `distance` stream is available if 5 km autolaps
need reconstructing by hand.

**Never call a fade from power alone.** A real fade is power declining *while HR holds or
climbs*. Split any suspect block into quarters and check both channels — falling HR alongside
falling power is a deliberate ease-off, not a failure. For this use
`intervals-icu streams <id> watts,heartrate` piped into `nix-shell -p python3`.

## Heat: get the temperature before reading HR

Ambient temperature is the strongest single predictor of whether a quality session lands, and
HR at a given power is close to uninterpretable without it. Roughly **8 bpm** separates 27 °C
from 30 °C at identical watts — enough to look exactly like under-recovery, and to get an FTP
wrongly rescaled downward.

Use the stream, not the summary field:

- `intervals-icu streams <id> temp` is a real per-second series, not a start-only value —
  Aug 1 2026 tracks 29 °C down to 20 °C across an evening.
- Average it **over the work intervals**, not the whole ride. The activity's `average_temp`
  can badly misrepresent them: Aug 1 averaged 23.5 °C while its first hour sat at 29 °C.
- Resolution is integer °C, and the sensor sits on the head unit, so it carries radiant and
  body heat. Reliable for comparing rides against each other; not a shaded air reading.

Worked comparison from this block: Jul 30's 4×12 held 273 W at HR 163–165 with its reps at
**26.8 °C**; Aug 3's 2×15 at the same watts ran its reps at **30.4 °C**, hit HR 181, and lost
rep 2. Same rider, four days apart, same nominal freshness.

Two corollaries:

- **Never rescale FTP off a hot-day session.**
- **Time of day is the lever, not the variable.** Jul 15 failed at 10:03 in 27 °C; Jul 27's
  VO2 5×5 landed in full at 16:44 in 23 °C. Judge the temperature, then use the clock to
  control it — start quality before 10:00 when the forecast tops 28 °C.

## Task

Compare what was actually ridden against the current week of the training plan at
`~/Documents/summer-training/summer-training-plan.typ` (read it if it is not already in
context). Report:

1. Quality sessions: did watts, durations, and reps match the plan's targets? If a session
   fell short, check the temperature during the reps before attributing it to fitness or fatigue.
2. Easy days: are they actually easy (IF below ~0.75, ideally lower)?
3. Weekly volume versus the plan.
4. Anything the plan should change — flag it with reasoning, do not silently edit the plan.
