# Single source for the coaching context, rendered once per harness.
#
# The Claude Code slash command and the dsh skill are the same document with
# different harness affordances, and only three things actually differ:
#
#   1. Claude Code expands !`date ...` and $ARGUMENTS before the model sees the
#      text; dsh does neither, so its copy asks for them in prose.
#   2. Claude Code denies the five Cronometer diary-writing tools through its
#      permission layer (see ../cronometer). dsh-mcp-client has no per-tool
#      allow/deny, so its copy has to carry the prohibition as an instruction.
#   3. The frontmatter keys are different, and dsh wants an H1.
#
# These were maintained as two hand-edited files until 2 Sep 2026 and had drifted
# 41 lines apart -- including, in the direction that mattered, the harness that
# *cannot* enforce read-only being the only one told not to write. The body now
# lives in ./body.md with @TOKENS@ and everything harness-specific lives here, so
# the two can no longer disagree about anything except the three points above.
#
# Both modules import this file directly rather than one importing the other, the
# same way ../claude-code's weather and intervals-icu wrappers are shared with
# ../dsh: same inputs, same text, so Nix lands on one derivation per output.
{ pkgs }:

let
  body = builtins.readFile ./body.md;

  render =
    tokens: builtins.replaceStrings (builtins.attrNames tokens) (builtins.attrValues tokens) body;

  claudeCodeBody = render {
    "@PROMPT@" = "prompt";

    "@TODAY@" = ''Today: !`date +"%A %-d %B %Y"`'';

    "@NO_PULL_PARA@" = ''
      **Nothing is pulled unless the prompt asks for it.** A bare `/coach`, or a question
      the repo already answers, reads files only. Fetch when the prompt asks for recent
      training ("pull the last 3 days", "how did this week go"), or when a claim needs
      evidence the repo does not hold.'';

    "@CRON_COUNT@" = "three";

    # Enforced by the permission layer here, so it needs no prose bullet.
    "@CRON_WRITE@" = "";

    "@CRON_TAIL@" = ''
       The five diary-writing tools
      are denied at the harness: cite a day, don't edit one.'';

    "@TASK_INPUT@" = ''
      Then:

      **$ARGUMENTS**

      It may carry notes on a ride just done, a question, a request to pull data, or
      several at once. Take it as written.'';

    "@EMPTY_CASE@" = "**Empty** — a bare `/coach`:";
  };

  dshBody = render {
    "@PROMPT@" = "request";

    "@TODAY@" = ''
      Run `date +"%A %-d %B %Y"` first — several rules below turn on where today sits
      in the block.'';

    "@NO_PULL_PARA@" = ''
      **Nothing is pulled unless the request asks for it.** A bare "how's the block
      going", or a question the repo already answers, reads files only. Fetch when the
      request asks for recent training ("pull the last 3 days", "how did this week go"),
      or when a claim needs evidence the repo does not hold.'';

    "@CRON_COUNT@" = "four";

    # Nothing stops these calls on this harness except this paragraph.
    "@CRON_WRITE@" = ''
      - **This harness cannot enforce read-only.** Under Claude Code the five
        diary-writing calls are denied by the permission layer; `dsh-mcp-client` has no
        per-tool allow/deny, so here they are merely *not to be used*.
        **Never call `add_food_entry`, `remove_food_entry`, `add_custom_food`,
        `copy_day`, or `mark_day_complete`.** Cronometer is an evidence base: cite a day,
        don't edit one.
    '';

    "@CRON_TAIL@" = "";

    "@TASK_INPUT@" = ''
      Then take the request as written. It may carry notes on a ride just done, a
      question, a request to pull data, or several at once.'';

    "@EMPTY_CASE@" = "**Nothing specific** —";
  };

  description = "Coach the summer training block (~/Documents/summer-training), closed 1 Sep 2026 at FTP 275 → 293 — the plan, the tooling, and the rules it earned.";
in
{
  # A path, as home-manager's claude-code `commands` attrset expects.
  command = pkgs.writeText "coach.md" ''
    ---
    description: ${description} Optionally pulls recent rides and nutrition.
    argument-hint: [notes, a question, and/or "pull the last N days"]
    allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(intervals-icu:*), Bash(weather:*), Bash(nix-shell:*), mcp__cronometer__get_food_log, mcp__cronometer__get_daily_nutrition, mcp__cronometer__get_nutrition_scores, mcp__cronometer__get_biometrics
    ---

    ${claudeCodeBody}
  '';

  # A directory, as dsh's tool-skill scanner expects: one SKILL.md per subdirectory.
  skills = pkgs.runCommand "dsh-skills" { } ''
    mkdir -p "$out/coach"
    cp ${
      pkgs.writeText "SKILL.md" ''
        ---
        name: coach
        description: ${description} Use when asked about training, a ride just done, FTP, fuelling, the session log, or whether a quality session should go ahead.
        ---

        # Coaching the summer training block

        ${dshBody}
      ''
    } "$out/coach/SKILL.md"
  '';
}
