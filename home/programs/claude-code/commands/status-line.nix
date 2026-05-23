{ pkgs }:
{
  type = "command";
  command = ''
    input=$(cat)
    used=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.context_window.used_percentage // empty')
    five=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.five_hour.used_percentage // empty')
    week=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.seven_day.used_percentage // empty')
    resets_at=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.five_hour.resets_at // empty')
    model=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name // empty')
    out=""
    [ -n "$used" ] && out="ctx:$(printf '%.0f' "$used")%"
    [ -n "$five" ] && out="$out 5h:$(printf '%.0f' "$five")%"
    [ -n "$week" ] && out="$out 7d:$(printf '%.0f' "$week")%"
    if [ -n "$resets_at" ]; then
      now=$(date +%s)
      remaining=$((resets_at - now))
      if [ "$remaining" -gt 0 ]; then
        hrs=$((remaining / 3600))
        mins=$(((remaining % 3600) / 60))
        out="$out $(printf '%dh%02d' "$hrs" "$mins")"
      fi
    fi
    [ -n "$model" ] && out="$out $model"
    echo "$out"
  '';
}
