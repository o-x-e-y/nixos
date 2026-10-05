cd "$1"
git add journal.txt
if git diff --cached --quiet; then
  git push -q origin HEAD
  exit 0
fi

# Entries are keyed by their timestamp header, numbered in case two share a
# minute. Trailing blank lines are dropped before comparing, since appending
# an entry adds a separator after the one before it.
summary=$(gawk '
  FNR == 1 { key = "" }
  /^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\] / {
    ts = substr($0, 1, 18)
    key = ts "#" (++seen[FILENAME, ts])
  }
  key != "" {
    if (FILENAME == ARGV[1]) old[key] = old[key] $0 "\n"
    else new[key] = new[key] $0 "\n"
  }
  END {
    for (k in new) {
      if (!(k in old)) added++
      else {
        a = old[k]; b = new[k]
        sub(/\n+$/, "", a); sub(/\n+$/, "", b)
        if (a != b) edited++
      }
    }
    for (k in old) if (!(k in new)) deleted++
    if (added) parts[++n] = added " added"
    if (edited) parts[++n] = edited " edited"
    if (deleted) parts[++n] = deleted " deleted"
    for (i = 1; i <= n; i++) printf "%s%s", (i > 1 ? ", " : ""), parts[i]
  }
' <(git show HEAD:journal.txt 2>/dev/null) journal.txt)

git commit -q -m "${summary:-formatting}"
git push -q origin HEAD
