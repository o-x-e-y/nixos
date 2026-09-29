The user logs their work with `ledger`, a wrapper around jrnl. An entry is a line of free text with a timestamp. `+name` is the project, added automatically from the git repo or directory the entry was written in; `@name` is a topic tag.

@TASK_INPUT@

## Reading the ledger

Only read it through `ledger --json`, followed by jrnl filters:

```bash
ledger --json -from "last monday" +dev-ledger
ledger --json -from 2026-09-01 -to 2026-09-30 @rust
ledger --json -contains "borrow checker" -n 20
```

- Several tags match any of them; `-and` requires all, `-not @tag` excludes one. Dates take natural language.
- The output has `tags` (counts) and `entries` (`date`, `time`, `title`, `body`, `tags`). jrnl splits an entry at its first sentence, so read `title` and `body` together.
- If the project or period is unclear, `ledger --json -n 30` shows what is there. Ask rather than guess.
- A `+project` is only a folder name. To look at the code, try the current directory, then `~/Repos/<name>`, and ask if neither is it.

Never add, edit or delete entries. The ledger is the user's own record: point out an entry that looks wrong and let them fix it.

## Writing from it

Recaps ("what did I do last week") are answered in chat. Documents follow the rules below.

**Skeleton only.** Set the document up, lay out its structure and propose its graphics. Nothing more:
- Headings, and under each a few notes on what belongs there, citing the entries that back it by date.
- Graphics as placeholders whose caption says what the figure shows, for example a C4 container diagram or a timeline of iterations.
- No finished prose unless the user asks for it in this conversation.

Format follows the target: a standalone document is Typst (**REQUIRED SUB-SKILL:** typst-writer), documentation inside a repository is Markdown in that repository.

Build the structure on these questions, as headings that fit the document rather than a numbered list:

1. What is the problem or question?
2. Why does it matter?
3. How was it approached?
4. What is the result?
5. What is its quality?
6. How was that validated?
7. What is the next step?

A full report maps them onto summary, introduction, method, results, conclusion and recommendations. Smaller documents take the part they need: a project plan, research document, technical design, test plan, implementation report or development log.

Decisions carry the document. For each choice the entries show, note the context, the alternatives, what settled it (research, a stakeholder, a prototype, a test) and the trade-offs, cost and security included. Order the story the way the work went: research and analysis, advice, design, building and testing, delivery.

Never invent work or reasons. Everything in the skeleton traces back to an entry, the project's files or something the user said. End with a short list, in chat, of what the ledger does not show: decisions without a reason, results without validation. Keep sources an entry mentions for an IEEE-style bibliography.

## School work

**REQUIRED SUB-SKILL:** when the document is for Fontys, school, a course, a portfolio or an assessment, load fontys before writing.
