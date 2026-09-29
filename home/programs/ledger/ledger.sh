# Anything starting with -, @ or + is a query or flag, not an entry
if [[ $# -gt 0 && $1 == [-@+]* ]]; then
  exec jrnl "$@"
fi

if [[ $# -eq 0 ]]; then
  read -e -r -p "ledger> " entry
  [[ -n $entry ]] || exit 0
else
  entry="$*"
fi

# An explicit +project wins over the directory
if [[ ! $entry =~ (^|[[:space:]])\+[[:alnum:]_] ]]; then
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  if [[ $root != "$HOME" ]]; then
    project=$(basename "$root")
    entry+=" +${project//[^[:alnum:]_-]/-}"
  fi
fi

exec jrnl "$entry"
