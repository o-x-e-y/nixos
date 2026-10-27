Handle a request about the user's work schedule at Pathé (ORTEC Employee Self
Service) with the `ortec` CLI: their shifts, swapping a shift with a colleague,
answering a colleague's swap request, and time off.

@TODAY@

@TASK_INPUT@

## The tool

`ortec` logs in as the user by itself and keeps its session in
`~/.cache/ortec/`. Its output is finished Markdown: **print it verbatim**, and
add a sentence of your own before or after if it helps. Run `ortec --help` when
you need a flag you are not sure of.

| the request is about | run |
|---|---|
| when they work | `ortec shifts [FROM [TO]]` |
| swap requests, sent or received | `ortec swaps [FROM [TO]]` |
| who could swap or take a shift | `ortec swap-candidates DATE [--give-away] [--their-date DATE]` |
| asking someone to swap | `ortec swap-request DATE COLLEAGUE [...]` |
| answering a request they received | `ortec swap-accept` / `ortec swap-decline DATE [--id N]` |
| their leave and its status | `ortec leaves [FROM [TO]]` |
| who they work with on a day they work | `ortec working-with [DATE [TO]]` |
| asking for time off | `ortec leave FROM [TO] [--type T]` |

Dates are `YYYY-MM-DD`, the short `MM-DD` and `DD` (the next such date, today
included), `today`/`vandaag`, `tomorrow`/`morgen`, or `+N` days. Work out
"Friday", "next week" and the like yourself from the date above and pass the
concrete date. A past date needs the full `YYYY-MM-DD`. One date on a listing
means that day only; no date means the coming weeks.

## Changing the schedule

`swap-request`, `swap-accept`, `swap-decline` and `leave` change the user's real
schedule at their job, and an accepted swap cannot be undone. They only print a
preview unless given `--yes`.

1. Run the command **without** `--yes` and print the preview.
2. Ask the user to confirm that exact preview.
3. Only after a clear yes, run the identical command again with `--yes`.

Never add `--yes` on your own initiative, never to a command whose preview the
user has not seen, and never because the request sounded decided ("just accept
it"). Show the preview anyway; it names both shifts and both people, which is
where mistakes get caught.

## Details that matter

**Swapping.** A swap is always for one of the user's shifts. Run
`swap-candidates DATE` first when the user has not said who, and let them pick.
`COLLEAGUE` is part of a name or the id shown there. A colleague with several
shifts that day needs `--their-shift` (id or start time); a user with several
shifts needs `--shift`. A colleague's shift on another day needs `--their-date`.
`--give-away` hands the shift over without getting one back.

**Answering a request.** `swap-accept DATE` finds the open request the user
*received* where either shift is on that date. The preview's "you get" is the
colleague's shift, "you give" is the user's. If several match, the error lists
them: ask which one, then pass `--id`. Requests the user sent cannot be accepted
by them.

**Leave.** Whole days: `ortec leave 2026-11-10` or `ortec leave 2026-11-10
2026-11-12` (inclusive). Part of a day: `ortec leave "2026-11-10 14:00" 18:00`.
The type defaults to the first one (Vakantie); `ortec leave-types` lists them.
A confirmed request runs the server's balance check first.

**Who they work with.** `ortec working-with` only answers for days the user has
a shift, and refuses any other day. That limit is deliberate: colleagues'
schedules are private, and the user chose to look only at days they work
themselves. Do not try to get around it with `swap-candidates --their-date` or
other commands. The list is whoever the swap screen shows for the user's own
shift, so it can miss people; a day marked incomplete has a swap request pending
that hides colleagues until it is settled.

**When it fails**, the error says why: no shift that day, an ambiguous name, a
refused balance check. Relay it and ask, rather than guessing a different
command. A login error means the credentials in `/run/secrets/ortec-*` or the
account itself; do not try to work around it.

**What it cannot do:** withdraw a swap request the user sent, or edit or delete
leave. Point the user at the ESS app for those.
