# One document for Claude Code and dsh, like ../coach, so the two can't drift.
# Claude Code expands !`date` and $ARGUMENTS where dsh's copy asks in prose,
# and the frontmatter differs.
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
    "@TODAY@" = ''
      Run `date +"%A %-d %B %Y (%Y-%m-%d)"` first — the date rules below read
      against it, and relative phrases like "this weekend" are worked out from
      what it prints.'';

    "@TASK_INPUT@" = ''
      Then take the request as written — the text that came with the invocation,
      or the question this was loaded for. It may name a film, a cinema, a day,
      a strand, or none of those.'';
  };

  # Also the summary dsh's catalog shows, so it decides when this gets loaded.
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

  # Invocation keys left unset, so the skill is both in the model's catalog and
  # typeable as `/pathe`.
  skills = pkgs.runCommand "dsh-skills-pathe" { } ''
    mkdir -p "$out/pathe"
    cp ${pkgs.writeText "SKILL.md" ''
      ---
      name: pathe
      description: ${description} Use when asked what is playing at Pathé, when a film plays, or about a strand like arthouse or Pride Night.
      ---

      # What is playing at Pathé

      ${dshBody}
    ''} "$out/pathe/SKILL.md"
  '';
}
