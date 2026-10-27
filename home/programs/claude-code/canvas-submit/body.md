`canvas-assignment` creates an assignment in the user's own FHICT Canvas course, adds it to the course module, optionally attaches a rubric, and optionally uploads a file and submits it as the user. The user decides what goes in; you run the command.

# Usage

```bash
canvas-assignment --name "<name>" [--desc "<html>"] [--rubric "<outcomes>"] [--doc <path>]
```

- `--name`: the assignment title. Always pass it. Without it the script opens `codium --wait` for an interactive form, which hangs when run from here.
- `--desc`: the description, as HTML. Optional.
- `--rubric`: comma-separated HBO-i learning outcomes, one rubric criterion each, named as Canvas titles them: `<Activity>-<Domain><Level>` such as `Analysis-S2`, `Advise-U1` or `Manage&Control-I3` (activities Analysis, Advise, Design, Realise, Manage&Control; domains S Software, U User Interaction, I Infrastructure, O Organisational processes, H Hardware), plus `PS-<Level>` and `PL-<Level>` for Professional Standard and Personal Leadership. Points, ratings and text come from the outcome. An unknown name stops the script before anything is created. Optional.
- `--doc`: the file to upload and submit. With it the assignment is published and the file handed in; without it the assignment is created unpublished and nothing is submitted.

Any other flag exits with `unrecognized arguments`.

# Running it

- Name, description, rubric and file come from the user. Ask for whatever is missing rather than making it up. Draft a description only when the user asks for one. You may suggest rubric outcomes from the competences in the fontys skill, but the user picks them.
- Show the exact command and wait for the user to confirm before running it. Every run creates a new assignment on Canvas, and there is no dry run.
- Pass the description through a quoted heredoc so quotes and newlines survive, and give `--doc` an absolute path:

```bash
DESC=$(cat <<'EOF'
<p>First paragraph.</p>
<p>Second paragraph.</p>
EOF
)
canvas-assignment --name "Assignment name" --desc "$DESC" --rubric "Analysis-S2,PL-1" --doc "/home/oxey/Documents/fontys/report.pdf"
```

# When it fails

The script stops at the first failed request and prints the Canvas error (`Error: POST … returned <status>: …`). The line before it tells you how far it got:

| Last progress line | State on Canvas |
|---|---|
| `Error: unknown outcome(s): …` | Nothing was created. Fix the outcome name and rerun. |
| `Creating assignment: …` | Nothing was created. Usually an expired API key (`/run/secrets/canvas-api-key`) or a course ID that no longer exists. |
| `Assignment created (id: N), adding to module...` | The assignment exists but is not in the module. |
| `Adding rubric: …` | The assignment exists and is in the module, but has no rubric. |
| `Uploading and submitting: …` | The assignment exists and is published, but nothing was handed in. |

Once an assignment exists, do not rerun the command: that creates a duplicate. Tell the user what state it is in so they can finish or delete it in Canvas.

The course and module IDs are hardcoded in `~/nixos/home/programs/canvas/canvas-assignment.py` and change every course year.
