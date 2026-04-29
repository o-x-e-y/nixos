{ pkgs, ... }:
let
  canvas-assignment = pkgs.writeShellApplication {
    name = "canvas-assignment";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      COURSE_ID="14809"
      MODULE_ID="115534"
      BASE_URL="https://fhict.instructure.com"
      API_KEY="$(cat /run/secrets/canvas-api-key)"

      tmpfile="$(mktemp /tmp/canvas-assignment-XXXXXX.md)"
      trap 'rm -f "$tmpfile"' EXIT

      cat > "$tmpfile" <<'TEMPLATE'
# Canvas Assignment — fill in below, then save and close the editor.
# Format:
#   First non-comment line  →  Assignment name
#   (blank line)
#   Everything after        →  Description (HTML supported)
#
# Example:
#   Week 3 Reflection
#
#   Write a 500-word reflection on the reading material.

TEMPLATE

      # CANVAS_EDITOR overrides VISUAL/EDITOR so you can use --wait for GUI editors
      # e.g. set CANVAS_EDITOR="zeditor --wait" in your shell
      codium --wait "$tmpfile"

      NAME="$(grep -v '^#' "$tmpfile" | grep -v '^[[:space:]]*$' | head -1)"
      if [ -z "$NAME" ]; then
        echo "Error: no assignment name found." >&2
        exit 1
      fi

      DESCRIPTION="$(awk '/^#/{next} found{print} /^[[:space:]]*$/ && !found{found=1}' "$tmpfile" | sed '/^[[:space:]]*$/d')"

      echo "Creating assignment: $NAME"

      ASSIGNMENT_ID="$(curl -sf \
        -X POST \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --arg name "$NAME" \
          --arg desc "$DESCRIPTION" \
          '{"assignment":{"name":$name,"description":$desc,"submission_types":["online_upload"],"published":false}}'
        )" \
        "$BASE_URL/api/v1/courses/$COURSE_ID/assignments" \
        | jq -r '.id')"

      echo "Assignment created (id: $ASSIGNMENT_ID), adding to module..."

      curl -sf \
        -X POST \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --argjson id "$ASSIGNMENT_ID" \
          '{"module_item":{"type":"Assignment","content_id":$id,"indent":1}}'
        )" \
        "$BASE_URL/api/v1/courses/$COURSE_ID/modules/$MODULE_ID/items" > /dev/null

      echo "Done! Assignment \"$NAME\" added to module."
    '';
  };
in
{
  home.packages = [ canvas-assignment ];

  home.sessionVariables.CANVAS_EDITOR = "codium --wait";
}
