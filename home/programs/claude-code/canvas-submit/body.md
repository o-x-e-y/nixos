`canvas-assignment` creates an assignment in the user's own FHICT Canvas course, adds it to the course module, optionally attaches a rubric, and optionally uploads a file and submits it as the user. When an assignment with that exact name already exists, it continues that one instead: it adds whatever is missing (module, rubric, description) and submits the file as a new attempt, which keeps the earlier versions. With `--course` it hands a file in to an existing assignment in one of the user's other courses, such as OLBCDFG-CMK. The user decides what goes in; you run the command.

# Usage

```bash
canvas-assignment --name "<name>" [--desc "<html>"] [--rubric "<outcomes>"] [--doc <path>]
canvas-assignment --course "<course>" --name "<assignment>" --doc <path>
```

- `--name`: the assignment title. Always pass it. Without it the script opens `codium --wait` for an interactive form, which hangs when run from here.
- `--desc`: the description, as HTML. On an existing assignment it replaces the description. Optional.
- `--rubric`: comma-separated HBO-i learning outcomes, one rubric criterion each, named as Canvas titles them: `<Activity>-<Domain><Level>` such as `Analysis-S2`, `Advise-U1` or `Manage&Control-I3` (activities Analysis, Advise, Design, Realise, Manage&Control; domains S Software, U User Interaction, I Infrastructure, O Organisational processes, H Hardware), plus `PS-<Level>` and `PL-<Level>` for Professional Standard and Personal Leadership. Points, ratings and text come from the outcome. An unknown name stops the script before anything is created. An existing assignment that already has a rubric keeps it. Optional.
- `--doc`: the file to upload and submit. With it the assignment is published and the file handed in; without it a new assignment is created unpublished and nothing is submitted.

- `--course`: a course name or id. The assignment must already exist there under exactly that name, and only `--doc` is handed in; nothing else about it can be changed. A course name that repeats across semesters means this semester's course. If the name is off, the error lists the course's assignments, so run it once with the user's wording and take the exact name from that list.

`canvas-assignment --delete "<id or name>"` deletes an assignment from the personal course, with any submission on it, and takes no other options. Use it only when the user asks to remove one, such as a duplicate or a mistake, and show the command and wait for confirmation like any other run. Several assignments sharing a name can only be deleted by id; the ambiguous-name error lists them. A deleted assignment can be restored from the course's undelete page, which the script prints.

Any other flag exits with `unrecognized arguments`.

# Running it

- Name, description, rubric and file come from the user. Ask for whatever is missing rather than making it up. Draft a description only when the user asks for one. You may suggest rubric outcomes from the competences in the fontys skill, but the user picks them.
- Show the exact command and wait for the user to confirm before running it. A run either creates an assignment or changes and submits to an existing one, and there is no dry run. Say which it will be: check the exact name with the user, since a near-miss creates a new assignment instead of continuing the old one.
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

The script stops at the first failed request and prints the Canvas error (`Error: POST … returned <status>: …`). Rerun the same command once the cause is fixed: it finds the assignment by name and picks up where it stopped. An expired API key (`/run/secrets/canvas-api-key`) shows up as a 401 on the first request.

`Error: <n> assignments are named "…"` means the name is ambiguous, and nothing was changed. Tell the user the ids so they can delete or rename the extras.

The personal course is the one the user teaches whose name ends in "personal course", and new assignments go into its first module. When a new semester starts, the user drags that semester's module to the top in Canvas.
