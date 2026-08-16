# Look up local weather from Open-Meteo.
#
# Exists to serve one decision: rule 1 of the training plan says heat is the
# variable and the clock is the lever, so what is needed is an *hourly* profile
# to pick a start time from — not a daily high. Every field below is one the
# plan's rules actually turn on.
#
# No API key, and therefore no secret: Open-Meteo is an unauthenticated GET.
#
# Past dates come from the archive endpoint (ERA5 reanalysis), not from the
# forecast endpoint's past_days. They are not interchangeable — measured on
# 2026-08-13 they differ by ~1.4 C, which is the same size as the head-unit
# offset this is used to check. Archive is authoritative for anything past.

FORECAST_API="https://api.open-meteo.com/v1/forecast"
ARCHIVE_API="https://archive-api.open-meteo.com/v1/archive"
TZ_NAME="Europe/Amsterdam"

# Head-unit temperature runs ~0.3-1.6 C above these air readings, measured on
# Aug 13 (+0.3) and Aug 15 (+1.6) 2026. Small enough that an air forecast is
# usable directly against rule 1's 26-28 / 28+ gates.
HOURLY="temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,precipitation_probability,cloud_cover,wind_speed_10m,wind_gusts_10m,wind_direction_10m"

usage() {
  cat <<'EOF'
Usage: weather <command> [args] [-l LOCATION]

  now                       Current conditions
  today [HH-HH]             Hourly table for today, optionally a window
  day <date> [HH-HH]        Hourly table for a date (YYYY-MM-DD, or +N / -N days)
  window <date> <HH-HH>     Summary over a session window

Locations (-l, default beek-en-donk):
  beek-en-donk | beek      51.5325, 5.6353
  eindhoven    | ehv       51.4416, 5.4697
  helmond                  51.4793, 5.6570
  <lat>,<lon>              any coordinate pair

Dates before today are pulled from the ERA5 archive; today and later from the
forecast. Temperatures are 2 m air; a head unit reads ~0.3-1.6 C higher.

  weather day +1 12-15      the window for tomorrow's session
  weather window 2026-08-13 08-10 -l helmond
EOF
}

LAT=51.5325
LON=5.6353
PLACE="Beek en Donk"

set_location() {
  case "${1,,}" in
    beek-en-donk | beek) LAT=51.5325 LON=5.6353 PLACE="Beek en Donk" ;;
    eindhoven | ehv) LAT=51.4416 LON=5.4697 PLACE="Eindhoven" ;;
    helmond) LAT=51.4793 LON=5.6570 PLACE="Helmond" ;;
    *)
      if [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?$ ]]; then
        LAT="${1%%,*}" LON="${1##*,}" PLACE="$LAT,$LON"
      else
        echo "error: unknown location '$1' (try beek-en-donk, eindhoven, helmond, or lat,lon)" >&2
        exit 1
      fi
      ;;
  esac
}

# Accepts YYYY-MM-DD, or a relative offset like +1 / -3, or today/tomorrow.
resolve_date() {
  case "$1" in
    today) date +%F ;;
    tomorrow) date -d "+1 day" +%F ;;
    yesterday) date -d "-1 day" +%F ;;
    +* | -*) date -d "$1 days" +%F ;;
    *)
      if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "$1"
      else
        echo "error: cannot read date '$1' (want YYYY-MM-DD, +N, -N, today, tomorrow)" >&2
        exit 1
      fi
      ;;
  esac
}

# Which endpoint owns this date. Kept separate from fetch_day so it can be read
# outside the command substitution fetch_day is normally called in.
source_for() {
  if [[ "$1" < "$(date +%F)" ]]; then echo archive; else echo forecast; fi
}

# Fetch the hourly block for one date, from whichever endpoint owns it.
fetch_day() {
  local d="$1" today url
  today=$(date +%F)
  if [ "$(source_for "$d")" = archive ]; then
    url="$ARCHIVE_API?latitude=$LAT&longitude=$LON&start_date=$d&end_date=$d&hourly=$HOURLY&timezone=$TZ_NAME"
  else
    local days
    days=$((($(date -d "$d" +%s) - $(date -d "$today" +%s)) / 86400 + 1))
    if [ "$days" -gt 16 ]; then
      echo "error: $d is beyond the 16-day forecast horizon" >&2
      exit 1
    fi
    url="$FORECAST_API?latitude=$LAT&longitude=$LON&hourly=$HOURLY&timezone=$TZ_NAME&forecast_days=$days"
  fi

  curl -sS --fail-with-body "$url" | jq --arg d "$d" '
    .hourly
    | [ .time, .temperature_2m, .apparent_temperature, .relative_humidity_2m,
        .precipitation, .precipitation_probability, .cloud_cover,
        .wind_speed_10m, .wind_gusts_10m, .wind_direction_10m ]
    | transpose
    | map(select(.[0] | startswith($d)))
    | map({
        time: .[0][11:16], temp: .[1], feels: .[2], rh: .[3],
        rain: .[4], prob: .[5], cloud: .[6],
        wind: .[7], gust: .[8], dir: .[9]
      })'
}

# "08-10" -> keeps 08:00 through 10:00 inclusive. Empty arg keeps everything.
filter_window() {
  local w="${1:-}"
  if [ -z "$w" ]; then
    cat
    return
  fi
  if [[ ! "$w" =~ ^([0-9]{1,2})-([0-9]{1,2})$ ]]; then
    echo "error: cannot read window '$w' (want HH-HH, e.g. 12-15)" >&2
    exit 1
  fi
  jq --argjson lo "${BASH_REMATCH[1]#0}" --argjson hi "${BASH_REMATCH[2]#0}" \
    'map(select((.time[0:2] | tonumber) as $h | $h >= $lo and $h <= $hi))'
}

compass() {
  jq -r 'def c: ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                 "S","SSW","SW","WSW","W","WNW","NW","NNW"][((. + 11.25) / 22.5 | floor) % 16];'"$1"
}

header() {
  local d="$1" label="${2:-}"
  printf '%s · %s%s · %s\n\n' \
    "$PLACE" "$(date -d "$d" '+%a %-d %b %Y')" "$label" "$(source_for "$d")"
}

print_table() {
  compass '
    (["time","temp","feels","rain","prob","cloud","wind","gust","dir"],
     (.[] | [ .time,
              (.temp   | tostring + " C"),
              (.feels  | tostring + " C"),
              (if .rain == 0 then "-" else (.rain | tostring + " mm") end),
              (if .prob == null then "-" else (.prob | tostring + "%") end),
              (.cloud  | tostring + "%"),
              (.wind   | tostring),
              (.gust   | tostring),
              (.dir | c) ]))
    | @tsv' | column -t -s$'\t'
}

print_summary() {
  compass '
    { n: length,
      t_lo: (map(.temp) | min), t_hi: (map(.temp) | max),
      t_mean: ((map(.temp) | add / length) * 10 | round / 10),
      f_lo: (map(.feels) | min), f_hi: (map(.feels) | max),
      rain: ((map(.rain) | add) * 10 | round / 10),
      # The archive endpoint carries no probability field, only what fell.
      prob: (if all(.[]; .prob == null) then null else (map(.prob // 0) | max) end),
      cloud: (map(.cloud) | add / length | round),
      rh: (map(.rh) | add / length | round),
      w_lo: (map(.wind) | min), w_hi: (map(.wind) | max),
      g_hi: (map(.gust) | max),
      dir: (map(.dir) | add / length | c) }
    | "  temp     \(.t_lo)-\(.t_hi) C   mean \(.t_mean)",
      "  feels    \(.f_lo)-\(.f_hi) C",
      "  rain     \(.rain) mm\(if .prob == null then " (measured)" else " total, peak probability \(.prob)%" end)",
      "  wind     \(.w_lo)-\(.w_hi) km/h from \(.dir), gusting \(.g_hi)",
      "  cloud    \(.cloud)%   humidity \(.rh)%",
      "",
      "  head unit will read roughly \(.t_mean + 1 | . * 10 | round / 10) C over this window."'
}

# --- argument handling -------------------------------------------------------

ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -l | --location)
      set_location "${2:?location required after $1}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

cmd="${ARGS[0]:-today}"

case "$cmd" in
  now)
    d=$(date +%F)
    h=$(date +%H)
    header "$d" " · $(date +%H:%M)"
    fetch_day "$d" | filter_window "$h-$h" | print_table
    ;;
  today)
    d=$(date +%F)
    win="${ARGS[1]:-}"
    body=$(fetch_day "$d" | filter_window "$win")
    header "$d" "${win:+ · ${win/-/:00–}:00}"
    echo "$body" | print_table
    ;;
  day)
    d=$(resolve_date "${ARGS[1]:?date required}")
    win="${ARGS[2]:-}"
    body=$(fetch_day "$d" | filter_window "$win")
    header "$d" "${win:+ · ${win/-/:00–}:00}"
    echo "$body" | print_table
    ;;
  window)
    d=$(resolve_date "${ARGS[1]:?date required}")
    win="${ARGS[2]:?window required, e.g. 12-15}"
    body=$(fetch_day "$d" | filter_window "$win")
    header "$d" " · ${win/-/:00–}:00"
    echo "$body" | print_summary
    ;;
  help)
    usage
    ;;
  *)
    echo "error: unknown command '$cmd'" >&2
    usage >&2
    exit 1
    ;;
esac
