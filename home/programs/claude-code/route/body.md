Plan public transport trips for the user with the `route` CLI: how to get
somewhere by a given time, when to leave, whether a plan fits, and the trip
back.

@TODAY@

@TASK_INPUT@

## The tool

`route` asks Google Routes for door-to-door options in the Netherlands:
train, bus, tram, metro and the walks in between. Always pass `--json` and
read the JSON. `route --help` documents the flags and times.

```sh
route --from "Station Eindhoven Centraal" --to "Pathé Tilburg Stappegoor" --arrive "2026-11-14 20:15" --json
route --from "Pathé Tilburg Stappegoor" --to 51.526654,5.634421 --depart "2026-11-14 22:40" --json
```

**Every call is one billed Google request**, capped locally at 600 per 7
days. One call per direction answers the question:

- `--arrive T` when something starts at a fixed time (a film, a shift, a
  lecture). It plans backwards: every option arrives at or before T.
- `--depart T` when the user is free from a fixed time (a shift or a film
  ends).

Don't scan a range of times, and don't ask again for a trip you already have
in this conversation. On `local limit reached` or `Google quota reached`,
stop and tell the user.

It plans from the timetable: no live delays, platforms or disruptions.

## Places

**Home** is Beek en Donk. The user bikes to the bus stop *Beek en Donk,
Lieshoutseweg* and takes bus 321 or 322 to and from Eindhoven Centraal. Plan
trips from or to home from or to that stop, given as coordinates, because the
name alone matches the street rather than the stop:

```
51.526654,5.634421
```

The bike ride isn't in the output, and its length isn't known. Write "bike to
Lieshoutseweg" before the bus, or "bike home" after it, without a time.
Cycling to Helmond station also works but is usually slower and less
convenient. Plan via `"Station Helmond"` only when the 321/322 doesn't fit,
e.g. late at night, and say why.

**Cinemas.** These names resolve to the right building:

- `"Pathé Helmond"`
- `"Pathé Eindhoven"`
- `"Pathé Tilburg Centrum"`
- `"Pathé Tilburg Stappegoor"`
- `"Pathé Tuschinski"` (Amsterdam)
- `"Pathé City"` (Amsterdam)

**Stations:** use `"Station <name>"`. Plain "Eindhoven Centraal" resolves to
a bar near the station.

**Check every answer's `from.types` and `to.types`.** Expected are
`movie_theater`, `train_station`, `transit_station` or an address. A
`locality` (it matched the town), a `bar` or anything else unexpected is a
wrong match. Say so and ask again with a more specific name or coordinates.

**Work.** When a trip starts or ends around a shift, the user says where they
work that day. Don't guess it. `ortec shifts DATE` gives the shift's times.

## Planning a trip

1. Pin the times down first: a showtime from `pathe`, a shift end from
   `ortec shifts`, or what the user said. Turn relative days into a concrete
   date from today's date above.
2. To **be somewhere at T**, pass T to `--arrive`. Prefer an option with
   about 10 minutes to spare, and point out the ones that arrive with less.
3. To **leave from somewhere at T**, pass T to `--depart`.
4. A **round trip** is two calls, one per direction. For a late return, the
   last workable option home decides whether the plan works. If nothing
   reasonable runs, say so plainly.

## Answering

Keep it short. For each direction, give the option you'd pick (leave,
arrive, lines, transfers), with one line for each alternative worth knowing:
one that leaves later, has fewer transfers or less walking. Mention the walk
to the first stop and the bike legs. Give the `maps_url`; it opens on
"leave now", so the time has to be set in Maps.

When it doesn't fit (the shift ends at 15:30 and every option arrives after
the film starts), say that first.

## Calendar

**Only touch Google Calendar after the user confirms.** Show exactly what
you'd create (title, start, end, description) and wait for a clear yes. The
same goes for changing or deleting an event.

One event per trip, in the primary calendar:

- **title:** `🚆 <from> → <to>`, e.g. `🚆 Pathé Eindhoven → Pathé Tilburg Stappegoor`
- **start / end:** the option's `depart` and `arrive`. For a trip from home
  that's the bus's departure: the bike ride comes before it.
- **colour:** Sage, `colorId: "2"`, green like Google Maps. The user's first
  choices, Pistachio and Avocado, are calendar colours that events can't
  have.
- **location:** the starting point.
- **description:** one line per leg (`15:51 Sprinter → Tilburg Universiteit:
  Eindhoven Centraal → Tilburg`, `bike to Lieshoutseweg`), then the
  `maps_url`.

The film or shift is its own event. Films are Banana, per the pathe skill,
and shifts are already in the ESS Shifts calendar. Don't merge them into the
trip.
