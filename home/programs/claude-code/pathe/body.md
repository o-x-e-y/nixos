Answer a question about what is playing at Pathé, using the `pathe` CLI.

@TODAY@

@TASK_INPUT@

## The tool

`pathe` is a read-only CLI over Pathé's public API. It cannot log in, see an
account, or book a seat — if the request wants tickets, say so and hand over the
booking URL the output carries, or point at pathe.nl.

It already prints finished Markdown, and that output is deterministic by design.
**Print what it returns verbatim.** Do not re-sort it, re-table it, translate it,
trim the metadata line, or fold several runs into a summary of your own. The
whole reason formatting lives in the tool is so the same question twice gives
the same bytes, ready to paste somewhere. Adding a sentence of your own before
or after is fine; rewriting the block is not.

Run `pathe --help` whenever the request needs a flag, tag or cinema slug you are
not sure of. It documents the full strand vocabulary, the filter rules, the date
syntax and every cinema slug, and it is kept current with the code.

## Choosing the command

| the request is about | run |
|---|---|
| what's on, a day's programme | `pathe programme [date]` |
| where a film is playing at all | `pathe where "<titel>"` |
| when and at what times a film plays | `pathe film "<titel>" --days N` |
| arthouse, In the Picture | `pathe arthouse` |
| Pride Night | `pathe pride` |
| classics, re-releases, old films | `pathe classics` |
| what's coming out | `pathe upcoming --limit N` |
| some other strand — ladies night, horror night, opera, ballet, sneak preview, kids | `pathe tagged <tag>` |
| which cinemas exist, which have IMAX/4DX | `pathe cinemas` |
| finding a title or its slug | `pathe search "<titel>"` |

**One call usually answers the question.** Reach for a second only when the
request genuinely has two parts. Don't loop over cinemas — pass them together to
`-c`, which is one call's worth of work to write and cheaper to run.

## Details that matter

**Cinemas.** Defaults to Helmond, Eindhoven, Tilburg Centrum and Tilburg
Stappegoor. Only pass `-c` when the request names cinemas, and then pass them
comma-separated: `-c helmond,eindhoven`. Short names work; `pathe cinemas` has
the full list.

**Dates.** `today`, `tomorrow`, `+N`, or `JJJJ-MM-DD`. Work out relative phrases
yourself from the date above — "this weekend", "next Friday", "over two weeks"
— and pass a concrete date or `--days` window. Default window is 60 days, so
say `--days 7` when the request is clearly about the near term.

**Filters.** Dubbed versions of foreign films and children's films are dropped
by default, and what went is named after `gefilterd:`. Leave that alone unless
the request wants them: `--include-kids` for a family outing, `--include-dubs`
for a Dutch-spoken screening, `--all` for both. Note `pathe film` never filters.

**Where versus when.** `where` costs one request and lists only the cinemas
that have the title; `film` fetches actual times for the cinemas you name. For
"where can I see X" run `where` first, then `film -c <the ones that matter>`.
Do not answer a "where" question by passing all 31 slugs to `film`.

**Favourites.** The default set comes from `~/.config/pathe/settings.json`.
`-f` selects it explicitly, which is what you want on `where` when the question
is only about the user's own cinemas.

**Formats** are per screening, not per film — the same title plays 4DX at 15:15
and flat at 20:15. If asked "is it in IMAX", read the rows, not the header.

**If a title isn't found**, run `pathe search` to resolve it before reporting
that it isn't playing; the catalogue title often differs from the spoken one.

**Never invent a screening.** If the output has no times, say there are none in
that window rather than reasoning about what is likely showing.
