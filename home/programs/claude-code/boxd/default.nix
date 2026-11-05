# One document for Claude Code and dsh, like ../pathe, so the two can't drift.
# Claude Code expands !`date` and $ARGUMENTS where dsh's copy asks in prose,
# and the frontmatter differs.
{
  pkgs,
  # The default only keeps this importable on its own.
  user ? "oxey",
}:

let
  # Rewritten by `/boxd refresh-taste`, which keeps the lines marked "by their
  # own account". Committed so every /boxd starts knowing the viewer at no
  # request cost; regenerate it when it drifts from the diary.
  taste = builtins.readFile ./taste.md;

  template = builtins.readFile ./body.md;

  body = builtins.replaceStrings [ "@USER@" "@TASTE@" ] [ user taste ] template;

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
      Run `date +"%A %-d %B %Y (%Y-%m-%d)"` first if the request turns on the
      date at all — "tonight", "this weekend", "what came out this year".'';

    "@TASK_INPUT@" = ''
      Then take the request as written — the text that came with the
      invocation, or the question this was loaded for. It may name a film, a
      mood, a runtime, a decade, or none of those.'';
  };

  # Also the summary dsh's catalog shows, so it decides when this gets loaded.
  description = builtins.replaceStrings [ "\n" ] [ " " ] ''
    The user's Letterboxd -- their watchlist, their ratings, what they have seen, and
    recommendations built on a profile of their taste. Read-only from public pages; it
    cannot rate, review, or add to a watchlist.'';

  skillDescription = builtins.replaceStrings [ "\n" ] [ " " ] ''
    ${description} Use when asked what to watch, what is on the watchlist, what they
    thought of a film, or for a film recommendation.'';

  argumentHint = builtins.concatStringsSep " | " [
    "what should I watch tonight"
    "is <film> on my watchlist"
    "recommend me something"
    "what did I think of <film>"
  ];
in
{
  # A string, not a path, for the reason given in ../pathe/default.nix.
  commandText = ''
    ---
    description: ${description}
    argument-hint: [${argumentHint}]
    allowed-tools: Bash(boxd:*), Bash(date:*)
    ---

    ${claudeCodeBody}
  '';

  # Invocation keys left unset, so the skill is both in the model's catalog and
  # typeable as `/boxd`.
  skills = pkgs.runCommand "dsh-skills-boxd" { } ''
    mkdir -p "$out/boxd"
    cp ${pkgs.writeText "SKILL.md" ''
      ---
      name: boxd
      description: ${skillDescription}
      ---

      # The user's Letterboxd

      ${dshBody}
    ''} "$out/boxd/SKILL.md"
  '';
}
