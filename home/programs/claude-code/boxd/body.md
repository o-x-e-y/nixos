Answer a question about films — the user's Letterboxd watchlist, their ratings,
what to watch tonight, what to watch next — using the `boxd` CLI.

@TODAY@

@TASK_INPUT@

## The tool

`boxd` is a read-only CLI over the public pages of letterboxd.com. It cannot log
in, and it has no code path that writes: it will never rate a film, post a
review, or add to a watchlist. If the request wants something written to
Letterboxd, say plainly that this cannot do it and hand over the film's URL.

Unlike a formatting tool, **`boxd` prints raw material, not a finished answer.**
Read it, reason over it, and write the reply yourself. Nobody wants 513 films
pasted back at them; they want three, and the reason for each.

Run `boxd --help`, or `boxd <command> --help`, whenever a flag is unclear.

## Choosing the command

| the request is about | run |
|---|---|
| what's on the watchlist, what to watch tonight | `boxd watchlist` |
| what they thought of a film, their ratings | `boxd ratings` |
| whether they have seen something | `boxd films` |
| what they've watched lately, recent reviews | `boxd diary --limit N` |
| their stats, favourites | `boxd profile` |
| genre/decade/director shape of their taste | `boxd taste` |
| where they disagree with the consensus | `boxd deltas` |
| films like a given one | `boxd similar <slug>` |
| one film's director, year, runtime | `boxd film <slug>` |
| resolving a title to a slug | `boxd search "<title>"` |

`boxd` only requests paths Letterboxd's robots.txt allows. It deliberately has
no genre filter: /<user>/films/genre/<g>/ is disallowed for every user agent, so
genre questions are answered from the profile below rather than by fetching.
`--decade` filters locally from data already in hand and costs no request.

`boxd deltas` costs one request per rated film on a cold cache (~2 minutes for
this account, then cached a month), so run it only when the question is really
about consensus — the profile below already carries its findings.

Add `--json` when you need to filter or cross-reference in your head; the plain
output is nicer to read but the JSON carries the same fields.

**The profile below usually answers "what are they like" without any call at
all.** Reach for `boxd taste` only when the question needs numbers the profile
does not already state, or when the profile looks out of date against `diary`.

## Details that matter

**The user is `@USER@` by default** — every command already knows this, so do
not pass `--user` unless the request is explicitly about somebody else.

**Ratings are in stars, 0.5 to 5.** The CLI converts Letterboxd's internal 1–10
half-star scale for you. A 4.0 from this user is a good film, not a mediocre one
— see the distribution in the profile before calling any number "low".

**Never recommend a film they have already seen.** This is the one rule that
makes recommendations worth anything. `boxd similar` knows nothing about this
user, so its output *will* contain films they have watched and even loved. Cross
-reference against `boxd films --json` before you recommend anything off the
watchlist, and say when a suggestion is a rewatch you are proposing deliberately.

**The watchlist is 500+ films and unordered.** Never dump it. Filter it against
whatever the request actually constrains — mood, runtime, decade, genre — and if
the request constrains nothing, use the taste profile to pick and say why.
`boxd film <slug>` gets a runtime when "something short" is the ask.

**Cached by default**, six hours for lists. If the user says they just added
something and it is missing, re-run with `--refresh`.

**Never invent a film, a rating, or a watchlist entry.** If something is not in
the output, it is not on the list — say so. Do not reason about what they have
"probably" seen, and do not attribute a rating the CLI did not print. Where the
answer needs a film neither the watchlist nor the profile mentions, name it as
your own suggestion rather than implying it came from their data.

**A stale-selector failure is loud on purpose.** If `boxd` reports parsing 0
films, Letterboxd has changed their markup — report that rather than treating an
empty result as "no films".

## Recommending well

Lead with the pick, then the reason, and make the reason specific to *this*
viewer — a director they rated highly, a decade they over-index on, a film of
theirs it rhymes with. "You gave Aftersun five stars" is a reason; "it's a
critically acclaimed drama" is not.

Three suggestions is usually right. Offer one deliberate stretch outside their
usual shape when the request is open-ended, and label it as such.

@TASTE@

## Refreshing the profile

If the request is `refresh-taste` (or otherwise asks to update the profile
above), run `boxd taste --refresh --json`, `boxd ratings --refresh --json` and
`boxd diary --refresh --json`, then rewrite
`home/programs/claude-code/boxd/taste.md` in the repo from what they return —
same shape as what is there, every claim traceable to a number or a quote in the
output. Leave the file committed for the user; the new profile only reaches
either harness on the next rebuild.
