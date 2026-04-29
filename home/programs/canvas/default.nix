{ pkgs, ... }:
let
  canvas-assignment = pkgs.writeShellApplication {
    name = "canvas-assignment";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      COURSE_ID="14809"
      MODULE_ID="115534"
      BASE_URL="https://fhict.instructure.com"
      API_KEY="$(cat /run/secrets/canvas-api-key)"

      NAME=""
      DESCRIPTION=""
      DOC_PATH=""
      USE_EDITOR=true

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --name) NAME="$2"; USE_EDITOR=false; shift 2 ;;
          --desc) DESCRIPTION="$2"; shift 2 ;;
          --doc)  DOC_PATH="$2"; shift 2 ;;
          *) echo "Unknown argument: $1" >&2; exit 1 ;;
        esac
      done

      if $USE_EDITOR; then
        tmpfile="$(mktemp /tmp/canvas-assignment-XXXXXX.md)"
        trap 'rm -f "$tmpfile"' EXIT

        cat > "$tmpfile" <<'TEMPLATE'
# Canvas Assignment — fill in below, then save and close the editor.
# Three sections separated by blank lines:
#   1. Assignment name (required)
#   2. Description — HTML supported (optional)
#   3. Path to a file to submit (optional)
#
# Example:
#   Week 3 Reflection
#
#   Write a 500-word reflection on the reading material.
#
#   /home/user/documents/reflection.pdf

TEMPLATE

        codium --wait "$tmpfile"

        mapfile -t -d $'\x00' SECTIONS < <(
          grep -v '^#' "$tmpfile" | awk 'BEGIN{RS=""; ORS="\0"} {print}'
        )

        if [ "''${#SECTIONS[@]}" -eq 0 ] || [ -z "''${SECTIONS[0]:-}" ]; then
          echo "Error: no assignment name found." >&2
          exit 1
        fi

        NAME="$(echo "''${SECTIONS[0]}" | head -1)"

        if [ "''${#SECTIONS[@]}" -ge 3 ]; then
          DESCRIPTION="''${SECTIONS[1]}"
          DOC_PATH="$(echo "''${SECTIONS[2]}" | tr -d '[:space:]')"
        elif [ "''${#SECTIONS[@]}" -eq 2 ]; then
          CANDIDATE="$(echo "''${SECTIONS[1]}" | tr -d '[:space:]')"
          if [[ "$CANDIDATE" == /* || "$CANDIDATE" == ~* ]]; then
            DOC_PATH="$CANDIDATE"
          else
            DESCRIPTION="''${SECTIONS[1]}"
          fi
        fi
      fi

      if [ -z "$NAME" ]; then
        echo "Error: no assignment name found." >&2
        exit 1
      fi

      PUBLISH=false
      [ -n "$DOC_PATH" ] && PUBLISH=true

      echo "Creating assignment: $NAME"

      ASSIGNMENT_ID="$(curl -sf \
        -X POST \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --arg name "$NAME" \
          --arg desc "$DESCRIPTION" \
          --argjson pub "$PUBLISH" \
          '{"assignment":{"name":$name,"description":$desc,"submission_types":["online_upload"],"published":$pub}}'
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

      if [ -n "$DOC_PATH" ]; then
        echo "Uploading and submitting: $DOC_PATH"

        UPLOAD_INFO="$(curl -sf \
          -X POST \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$(jq -n \
            --arg name "$(basename "$DOC_PATH")" \
            --argjson size "$(stat -c%s "$DOC_PATH")" \
            '{"name":$name,"size":$size}'
          )" \
          "$BASE_URL/api/v1/courses/$COURSE_ID/assignments/$ASSIGNMENT_ID/submissions/self/files")"

        UPLOAD_URL="$(echo "$UPLOAD_INFO" | jq -r '.upload_url')"

        UPLOAD_ARGS=()
        while IFS= read -r pair; do
          UPLOAD_ARGS+=("--form-string" "$pair")
        done < <(echo "$UPLOAD_INFO" | jq -r '.upload_params | to_entries[] | "\(.key)=\(.value)"')
        UPLOAD_ARGS+=("-F" "file=@$DOC_PATH")

        FILE_ID="$(curl -sfL "''${UPLOAD_ARGS[@]}" "$UPLOAD_URL" | jq -r '.id')"

        curl -sf \
          -X POST \
          -H "Authorization: Bearer $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$(jq -n \
            --argjson fid "$FILE_ID" \
            '{"submission":{"submission_type":"online_upload","file_ids":[$fid]}}'
          )" \
          "$BASE_URL/api/v1/courses/$COURSE_ID/assignments/$ASSIGNMENT_ID/submissions" > /dev/null

        echo "File submitted!"
      fi
    '';
  };
in
{
  home.packages = [ canvas-assignment ];

  home.sessionVariables.CANVAS_EDITOR = "codium --wait";
}
