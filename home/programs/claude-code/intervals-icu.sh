# Fetch training data from intervals.icu.
# The API key is read from the sops-decrypted secret at request time and is
# passed to curl via a stdin config so it never appears in argv or output.

ATHLETE="i563199"
KEYFILE="${INTERVALS_ICU_KEYFILE:-/run/secrets/intervals_icu_key}"
BASE="https://intervals.icu/api/v1"

usage() {
  cat <<'EOF'
Usage: intervals-icu <command> [args]

  activities [days]      Compact summary of activities from the last N days (default 14)
  activity <id>          Full JSON for one activity (large)
  intervals <id>         Per-interval breakdown of one activity
  streams <id> [types]   Raw streams, default types: time,watts,heartrate,cadence (very large)
  wellness [days]        Wellness log (weight, resting HR, sleep, HRV) for the last N days
  get <path>             Raw GET against https://intervals.icu/api/v1<path>

Activity ids look like "i79808468" and come from the activities listing.
API reference: https://intervals.icu/api-docs.html
EOF
}

get() {
  if [ ! -r "$KEYFILE" ]; then
    echo "error: cannot read API key at $KEYFILE (is the sops secret deployed?)" >&2
    exit 1
  fi
  curl -sS --fail-with-body -K - "$BASE$1" <<EOF
user = "API_KEY:$(cat "$KEYFILE")"
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
  activities)
    days="${1:-14}"
    oldest=$(date -d "-$days days" +%F)
    newest=$(date -d "+1 day" +%F)
    get "/athlete/$ATHLETE/activities?oldest=$oldest&newest=$newest" | jq '
      [ .[] | {
          id,
          date: .start_date_local,
          name,
          type,
          h: ((.moving_time // 0) / 360 | round / 10),
          km: ((.distance // 0) / 100 | round / 10),
          avg_w: .icu_average_watts,
          np_w: .icu_weighted_avg_watts,
          intensity: .icu_intensity,
          load: .icu_training_load,
          avg_hr: .average_heartrate,
          max_hr: .max_heartrate
        } ]'
    ;;
  activity)
    get "/activity/${1:?activity id required}"
    ;;
  intervals)
    get "/activity/${1:?activity id required}/intervals" | jq '{
      intervals: [ (.icu_intervals // [])[] | {
        type,
        label,
        secs: (.elapsed_time // .moving_time),
        avg_w: .average_watts,
        max_w: .max_watts,
        avg_hr: .average_heartrate,
        intensity
      } ]
    }'
    ;;
  streams)
    id="${1:?activity id required}"
    types="${2:-time,watts,heartrate,cadence}"
    get "/activity/$id/streams?types=$types"
    ;;
  wellness)
    days="${1:-14}"
    get "/athlete/$ATHLETE/wellness?oldest=$(date -d "-$days days" +%F)"
    ;;
  get)
    get "${1:?path required}"
    ;;
  "" | -h | --help | help)
    usage
    ;;
  *)
    echo "error: unknown command '$cmd'" >&2
    usage >&2
    exit 1
    ;;
esac
