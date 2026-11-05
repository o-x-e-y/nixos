`canvas assignment` creates an assignment in a Canvas course the user teaches, by default their personal FHICT course, adds it to a module, optionally attaches a rubric, and optionally uploads files and submits them as the user. When an assignment with that exact name already exists, it continues that one instead: it adds whatever is missing (module, rubric, description) and submits the files as a new attempt, which keeps the earlier versions. `canvas hand-in` hands in to an existing assignment in one of the user's other courses, by default OLBCDFG-CMK. The user decides what goes in; you run the command.

# Usage

```bash
canvas assignment --name "<name>" [--desc "<html>"] [--rubric "<rubric or outcomes>"] [--doc <path>]... [--publish] [--indent N] [--after "<header>"]
canvas hand-in [-c <course>] --name "<assignment>" (--doc <path>... | --url <url> | --text "<html>")
canvas delete "<id or name>" --yes
```

- `-c`: the course, on any command: a nickname from the settings (`personal`, `general`), a course id, or the course's full name. Without it, `assignment` and `delete` use `personal` and `hand-in` uses `general`. `canvas courses` lists the user's courses and nicknames, `canvas modules` a course's modules and headers. A warning that a course has ended means the settings point at last semester's course; tell the user.
- `--name`: the assignment title. Always pass it. Without it the command opens `codium --wait` for an interactive form, which hangs when run from here.
- `--desc`: the description, as HTML. On an existing assignment it replaces the description. Optional.
- `--rubric`: the exact title of a rubric the course already has, which is attached as it is, or comma-separated HBO-i learning outcomes, one rubric criterion each, named as Canvas titles them: `<Activity>-<Domain><Level>` such as `Analysis-S2`, `Advise-U1` or `Manage&Control-I3` (activities Analysis, Advise, Design, Realise, Manage&Control; domains S Software, U User Interaction, I Infrastructure, O Organisational processes, H Hardware), plus `PS-<Level>` and `PL-<Level>` for Professional Standard and Personal Leadership. Points, ratings and text come from the outcome. An unknown name stops the command before anything is created; when a title matches several outcomes, the error lists their ids, which `--rubric` also takes. An existing assignment that already has a rubric keeps it. Optional.
- `--doc`: a file to upload and submit; repeat it for several files. With it the assignment is published and the files handed in; without it a new assignment is created unpublished and nothing is submitted.
- `--publish`: publish the assignment without handing anything in, for work that is not ready yet. Optional.
- `--indent` and `--after`: where a new assignment lands in its module. Assignments sit at indent 1 under headers at indent 0, which is the personal course's default. `--after "<header>"` puts it at the end of that header's group instead of the end of the module, such as `--after "Group Project: InnerGames Prototyping"`; use it whenever the assignment belongs to a group that isn't the last one in the module. Both only apply when the assignment is added to a module, not to one already in it.

`hand-in` needs an assignment that already exists under exactly that name; only the files, URL or text are handed in, and nothing else about the assignment can be changed. The assignment must take that kind of submission. A course name that repeats across semesters means this semester's course. If the name is off, the error lists the course's assignments, so run it once with the user's wording and take the exact name from that list.

`canvas delete` deletes an assignment, by default from the personal course, with any submission on it. Use it only when the user asks to remove one, such as a duplicate or a mistake. Without `--yes` it asks on the terminal, which you can't answer, so show the command and wait for the user's confirmation like any other run, then pass `--yes`. Several assignments sharing a name can only be deleted by id; the ambiguous-name error lists them. A deleted assignment can be restored from the course's undelete page, which the command prints.

Any other flag exits with `unrecognized arguments`. `canvas <command> --help` lists what each command takes.

# Running it

- Name, description, rubric and files come from the user. Ask for whatever is missing rather than making it up. Draft a description only when the user asks for one. You may suggest rubric outcomes from the competences in the fontys skill, but the user picks them.
- Show the exact command and wait for the user to confirm before running it. A run either creates an assignment or changes and submits to an existing one, and there is no dry run. Say which it will be: check the exact name with the user, since a near-miss creates a new assignment instead of continuing the old one. `canvas modules` shows the existing assignments and headers, which helps with both the name and `--after`.
- Pass the description through a quoted heredoc so quotes and newlines survive, and give `--doc` an absolute path:

```bash
DESC=$(cat <<'EOF'
<p>First paragraph.</p>
<p>Second paragraph.</p>
EOF
)
canvas assignment --name "Assignment name" --desc "$DESC" --rubric "Analysis-S2,PL-1" --after "Group Project: InnerGames Prototyping" --doc "/home/oxey/Documents/fontys/report.pdf"
```

# When it fails

The command stops at the first failed request and prints why. Rerun the same command once the cause is fixed: it finds the assignment by name and picks up where it stopped, and an error halfway through says which step it was on.

- `Canvas doesn't allow this: …` is Canvas refusing the action in that course, with its own message; the user's role there doesn't permit it. Don't retry or work around it; tell the user.
- `Canvas rejected the access token …` means the API key in `/run/secrets/canvas-api-key` expired or was revoked; the user has to make a new one.
- `<n> assignments are named "…"` means the name is ambiguous, and nothing was changed. Tell the user the ids so they can delete or rename the extras.
- `… needs -c COURSE` means the command has no default course; ask the user which course they mean.
