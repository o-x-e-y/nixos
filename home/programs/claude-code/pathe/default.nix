# Single source for the Pathé context, rendered once per harness.
#
# The Claude Code slash command and the dsh skill are the same document, and
# only two things actually differ:
#
#   1. Claude Code expands !`date ...` and $ARGUMENTS before the model sees the
#      text; dsh does neither, so its copy asks for the date and names the
#      request in prose.
#   2. The frontmatter keys are different, and dsh wants an H1.
#
# Built the way ../coach is: the body lives in ./body.md, everything
# harness-specific is a token or a frontmatter key in this file, and both
# modules import it directly rather than one importing the other -- same inputs,
# same text, so Nix lands on one derivation per output.
{ pkgs }:

let
  body = builtins.readFile ./body.md;

  render =
    tokens: builtins.replaceStrings (builtins.attrNames tokens) (builtins.attrValues tokens) body;

  claudeCodeBody = render {
    "@TODAY@" = ''Today: !`date +"%A %-d %B %Y (%Y-%m-%d)"`'';

    "@TASK_INPUT@" = ''
      **The request:**

      $ARGUMENTS'';
  };

  dshBody = render {
    # "the date above" below is this date: dsh expands nothing, so the model has
    # to go and get it before the relative phrases can mean anything.
    "@TODAY@" = ''
      Run `date +"%A %-d %B %Y (%Y-%m-%d)"` first — the date rules below read
      against it, and relative phrases like "this weekend" are worked out from
      what it prints.'';

    # Nothing substitutes the invocation here either. A `/pathe` gesture leaves
    # the rest of the message in front of the model; a plain load arrives with
    # the question that prompted it.
    "@TASK_INPUT@" = ''
      Then take the request as written — the text that came with the invocation,
      or the question this was loaded for. It may name a film, a cinema, a day,
      a strand, or none of those.'';
  };

  # The one string both frontmatters share, and the summary dsh's catalog shows.
  # Worded exactly as it was when this was a command only: it is what decides
  # whether the document is the right one to load, so the refactor is not the
  # place to reword it.
  description = "What is playing at Pathé -- a day's programme, when a given film plays, and the arthouse (In the Picture), Pride Night and classics strands. Read-only from the public Pathé API; it cannot book a seat.";
in
{
  # A string, not a path: home-manager's claude-code module routes `commands`
  # entries through `if lib.isPath content then source else text`, and a
  # derivation is neither a path nor a string as far as that check is concerned.
  commandText = ''
    ---
    description: ${description}
    argument-hint: [wat draait er vanavond | wanneer draait <film> | arthouse | pride | classics]
    allowed-tools: Bash(pathe:*), Bash(date:*)
    ---

    ${claudeCodeBody}
  '';

  # A directory, as dsh's tool-skill scanner expects: one SKILL.md per
  # subdirectory, discovered at the top level of a scanned root. Leaving both
  # invocation keys unset is deliberate -- it keeps `pathe` in the model
  # catalog *and* makes `/pathe` a gesture a person can type, which is the
  # closest this harness has to the slash command above.
  skills = pkgs.runCommand "dsh-skills-pathe" { } ''
    mkdir -p "$out/pathe"
    cp ${
      pkgs.writeText "SKILL.md" ''
        ---
        name: pathe
        description: ${description} Use when asked what is playing at Pathé, when a film plays, or about a strand like arthouse or Pride Night.
        ---

        # What is playing at Pathé

        ${dshBody}
      ''
    } "$out/pathe/SKILL.md"
  '';
}
