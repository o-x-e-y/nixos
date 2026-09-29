---
description: Use when the user wants to create an assignment on Canvas or hand in a document, usually a compiled Typst PDF, on Canvas.
argument-hint: [assignment name] [path to file]
---

`canvas-assignment` creates an assignment in the user's own FHICT Canvas course, adds it to the course module, and optionally uploads a file and submits it as the user. The user decides what goes in; you run the command.

# Usage

```bash
canvas-assignment --name "<name>" [--desc "<html>"] [--doc <path>]
```

- `--name`: the assignment title. Always pass it. Without it the script opens `codium --wait` for an interactive form, which hangs when run from here.
- `--desc`: the description, as HTML. Optional.
- `--doc`: the file to upload and submit. With it the assignment is published and the file handed in; without it the assignment is created unpublished and nothing is submitted.

There is no `--help`; any other flag exits with `Unknown argument`.

# Running it

- Name, description and file come from the user. Ask for whatever is missing rather than making it up. Draft a description only when the user asks for one.
- Show the exact command and wait for the user to confirm before running it. Every run creates a new assignment on Canvas, and there is no dry run.
- Pass the description through a quoted heredoc so quotes and newlines survive, and give `--doc` an absolute path:

```bash
DESC=$(cat <<'EOF'
<p>First paragraph.</p>
<p>Second paragraph.</p>
EOF
)
canvas-assignment --name "Assignment name" --desc "$DESC" --doc "/home/oxey/Documents/fontys/report.pdf"
```

# When it fails

The script stops silently at the first failed request, so the last line it printed tells you how far it got:

| Last line | State on Canvas |
|---|---|
| `Creating assignment: …` | Nothing was created. Usually an expired API key (`/run/secrets/canvas-api-key`) or a course ID that no longer exists. |
| `Assignment created (id: N), adding to module...` | The assignment exists but is not in the module. |
| `Uploading and submitting: …` | The assignment exists and is published, but nothing was handed in. |

Once an assignment exists, do not rerun the command: that creates a duplicate. Tell the user what state it is in so they can finish or delete it in Canvas.

The course and module IDs are hardcoded in `~/nixos/home/programs/canvas/default.nix` and change every course year.
