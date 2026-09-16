# Single source for the Letterboxd context, rendered once per harness.
#
# Built exactly the way ../pathe is, and for the same reason: the Claude Code
# slash command and the dsh skill are the same document, so keeping them as two
# hand-maintained files is how they drift. Only two things actually differ:
#
#   1. Claude Code expands !`date ...` and $ARGUMENTS before the model sees the
#      text; dsh does neither, so its copy asks for the date and names the
#      request in prose.
#   2. The frontmatter keys are different, and dsh wants an H1.
#
# The body lives in ./body.md, the viewer profile in ./taste.md, everything
# harness-specific is a token or a frontmatter key here, and both modules import
# this directly rather than one importing the other -- same inputs, same text,
# so Nix lands on one derivation per output.
{
  pkgs,
  # The default username the document should talk about. Passed by both call
  # sites from `config.apps.boxd.user` so the two land on one derivation; the
  # default here only keeps this importable on its own.
  user ? "oxey",
}:

let
  # ./taste.md is a generated artefact, not a hand-written one: `/boxd
  # refresh-taste` re-runs `boxd taste` and `boxd ratings` and rewrites it. It
  # is interpolated into the body rather than fetched at invocation time so that
  # every /boxd starts already knowing this viewer at zero request cost -- which
  # is the whole point of committing it. Regenerate it when it drifts from the
  # diary, not on a schedule.
  taste = builtins.readFile ./taste.md;

  body = builtins.replaceStrings
    [ "@USER@" "@TASTE@" ]
    [ user taste ]
    (builtins.readFile ./body.md);

  render =
    tokens: builtins.replaceStrings (builtins.attrNames tokens) (builtins.attrValues tokens) body;

  claudeCodeBody = render {
    "@TODAY@" = ''Today: !`date +"%A %-d %B %Y (%Y-%m-%d)"`'';

    "@TASK_INPUT@" = ''
      **The request:**

      $ARGUMENTS'';
  };

  dshBody = render {
    # dsh expands nothing, so the model has to go and get the date before
    # anything relative ("tonight", "this weekend") can mean anything.
    "@TODAY@" = ''
      Run `date +"%A %-d %B %Y (%Y-%m-%d)"` first if the request turns on the
      date at all — "tonight", "this weekend", "what came out this year".'';

    # Nothing substitutes the invocation here either. A `/boxd` gesture leaves
    # the rest of the message in front of the model; a plain load arrives with
    # the question that prompted it.
    "@TASK_INPUT@" = ''
      Then take the request as written — the text that came with the
      invocation, or the question this was loaded for. It may name a film, a
      mood, a runtime, a decade, or none of those.'';
  };

  # The one string both frontmatters share, and the summary dsh's catalog shows.
  # It is what decides whether this document is the right one to load, so it
  # names the three things it is actually for.
  description = "The user's Letterboxd -- their watchlist, their ratings, what they have seen, and recommendations built on a profile of their taste. Read-only from public pages; it cannot rate, review, or add to a watchlist.";
in
{
  # A string, not a path: home-manager's claude-code module routes `commands`
  # entries through `if lib.isPath content then source else text`, and a
  # derivation is neither a path nor a string as far as that check is concerned.
  commandText = ''
    ---
    description: ${description}
    argument-hint: [what should I watch tonight | is <film> on my watchlist | recommend me something | what did I think of <film>]
    allowed-tools: Bash(boxd:*), Bash(date:*)
    ---

    ${claudeCodeBody}
  '';

  # A directory, as dsh's tool-skill scanner expects: one SKILL.md per
  # subdirectory, discovered at the top level of a scanned root. Leaving both
  # invocation keys unset is deliberate -- it keeps `boxd` in the model catalog
  # *and* makes `/boxd` a gesture a person can type, which is the closest this
  # harness has to the slash command above.
  skills = pkgs.runCommand "dsh-skills-boxd" { } ''
    mkdir -p "$out/boxd"
    cp ${
      pkgs.writeText "SKILL.md" ''
        ---
        name: boxd
        description: ${description} Use when asked what to watch, what is on the watchlist, what they thought of a film, or for a film recommendation.
        ---

        # The user's Letterboxd

        ${dshBody}
      ''
    } "$out/boxd/SKILL.md"
  '';
}
