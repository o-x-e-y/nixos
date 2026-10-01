# Prints nothing in $HOME, which isn't a project
project_tag() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  if [[ $root != "$HOME" ]]; then
    root=$(basename "$root")
    echo "+${root//[^[:alnum:]_-]/-}"
  fi
}

# Read-only: jrnl never writes with --format set, and only filters get through.
# Claude's permissions allow this form and nothing else.
if [[ ${1-} == --json ]]; then
  shift
  for arg in "$@"; do
    case $arg in
      -on | -today-in-history | -month | -day | -year | -from | -to | -until | -contains | -and | -starred | -tagged | -n | -not | -[0-9]*) ;;
      -*)
        echo "ledger --json only takes filters, not $arg" >&2
        exit 1
        ;;
    esac
  done
  exec jrnl --format json "$@"
fi

if [[ ${1-} == -h || ${1-} == --here ]]; then
  shift
  tag=$(project_tag)
  if [[ -z $tag ]]; then
    echo "ledger --here needs a project directory, not $HOME" >&2
    exit 1
  fi
  exec jrnl "$tag" "$@"
fi

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
  tag=$(project_tag)
  if [[ -n $tag ]]; then
    entry+=" $tag"
  fi
fi

exec jrnl "$entry"
