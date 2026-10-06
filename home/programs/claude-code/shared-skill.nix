# One document rendered for both harnesses, like ./pathe and ./boxd, for skills
# whose only harness-specific parts are the request and the date: Claude Code
# substitutes $ARGUMENTS and expands !`date`, dsh does neither, so its copy
# names the request in prose and asks for the date to be run. The frontmatter
# keys differ too, and dsh wants an H1.
#
# A body without @TASK_INPUT@ comes through unchanged: Claude Code appends the
# arguments itself when the command never mentions them. A body with @TODAY@
# needs `Bash(date:*)` in allowedTools for Claude Code to expand it.
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

  render =
    tokens:
    builtins.replaceStrings (builtins.attrNames tokens) (builtins.attrValues tokens) (
      builtins.readFile body
    );
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
      (render {
        "@TODAY@" = ''Today: !`date +"%A %-d %B %Y (%Y-%m-%d)"`'';
        "@TASK_INPUT@" = ''
          **The request:**

          $ARGUMENTS'';
      })
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

      ${render {
        "@TODAY@" =
          ''Run `date +"%A %-d %B %Y (%Y-%m-%d)"` first; everything below that says "today" reads against what it prints.'';
        "@TASK_INPUT@" =
          "Take the request as written: the text that came with the invocation, or the question this was loaded for.";
      }}
    ''} "$out/${name}/SKILL.md"
  '';
}
