# One document rendered for both harnesses, like ./pathe and ./boxd, for skills
# whose only harness-specific part is the request: Claude Code substitutes
# $ARGUMENTS, dsh substitutes nothing, so its copy names the request in prose.
# The frontmatter keys differ too, and dsh wants an H1.
#
# A body without @TASK_INPUT@ comes through unchanged: Claude Code appends the
# arguments itself when the command never mentions them.
{ pkgs }:
{
  name,
  title,
  description,
  body,
  argumentHint ? null,
  allowedTools ? null,
}:

let
  inherit (pkgs) lib;

  render = input: builtins.replaceStrings [ "@TASK_INPUT@" ] [ input ] (builtins.readFile body);
in
{
  # A string, not a path, for the reason given in ./pathe/default.nix.
  commandText = lib.concatStringsSep "\n" (
    [
      "---"
      "description: ${description}"
    ]
    ++ lib.optional (argumentHint != null) "argument-hint: ${argumentHint}"
    ++ lib.optional (allowedTools != null) "allowed-tools: ${allowedTools}"
    ++ [
      "---"
      ""
      (render ''
        **The request:**

        $ARGUMENTS'')
    ]
  );

  skills = pkgs.runCommand "dsh-skills-${name}" { } ''
    mkdir -p "$out/${name}"
    cp ${pkgs.writeText "SKILL.md" ''
      ---
      name: ${name}
      description: ${description}
      ---

      # ${title}

      ${render "Take the request as written: the text that came with the invocation, or the question this was loaded for."}
    ''} "$out/${name}/SKILL.md"
  '';
}
