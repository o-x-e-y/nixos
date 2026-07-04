---
description: Pull recent rides from intervals.icu and review them against the summer training plan
argument-hint: [days]
allowed-tools: Bash(intervals-icu:*), Read, Grep, Glob
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

- `intervals-icu intervals <id>` — per-interval breakdown of a quality session (targets vs. actual watts)
- `intervals-icu wellness [days]` — weight, resting HR, sleep, HRV
- `intervals-icu activity <id>` — full activity JSON (large; rarely needed)
- `intervals-icu streams <id> [types]` — per-second data (very large; only for deep dives)
- `intervals-icu get <path>` — anything else, see https://intervals.icu/api-docs.html

## Task

Compare what was actually ridden against the current week of the training plan at
`~/Documents/summer-training/summer-training-plan.typ` (read it if it is not already in
context). Report:

1. Quality sessions: did watts, durations, and reps match the plan's targets?
2. Easy days: are they actually easy (IF below ~0.75, ideally lower)?
3. Weekly volume versus the plan.
4. Anything the plan should change — flag it with reasoning, do not silently edit the plan.
