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

## Task

Compare what was actually ridden against the current week of the training plan at
`~/Documents/summer-training/summer-training-plan.typ` (read it if it is not already in
context). Report:

1. Quality sessions: did watts, durations, and reps match the plan's targets?
2. Easy days: are they actually easy (IF below ~0.75, ideally lower)?
3. Weekly volume versus the plan.
4. Anything the plan should change — flag it with reasoning, do not silently edit the plan.
