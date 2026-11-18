{ pkgs }:
pkgs.writeShellApplication {
  name = "claude-usage-guard";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.jq
  ];
  text = ''
    [ -n "''${CLAUDE_USAGE_GUARD:-}" ] || exit 0

    file="$HOME/.claude/rate-limits.json"
    [ -r "$file" ] || exit 0

    now=$(date +%s)
    hit=$(jq -r --argjson now "$now" --argjson t 90 '
      to_entries[]
      | select(.value.resets_at > $now and .value.used_percentage >= $t)
      | "\(.key) window at \(.value.used_percentage | floor)%, resets in \((.value.resets_at - $now) / 60 | floor) min"
    ' "$file")

    if [ -n "$hit" ]; then
      printf 'Usage guard: %s. Stopping at 90%% so some allowance is left for basic tasks.\n' "$hit" >&2
      exit 2
    fi
  '';
}
