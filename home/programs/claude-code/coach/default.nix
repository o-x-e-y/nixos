# One document for Claude Code and dsh; as two files they had drifted 41 lines
# apart by 2 Sep 2026. Claude Code expands !`date` and $ARGUMENTS where dsh's
# copy asks in prose, and the frontmatter differs.
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

    "@TASK_INPUT@" = ''
      Then take the request as written. It may carry notes on a ride just done, a
      question, a request to pull data, or several at once.'';

    "@EMPTY_CASE@" = "**Nothing specific** —";
  };

  description = "Coach the winter training block (~/Documents/winter-training) — base through spring, aimed at WVAN crits from early April 2027, on FTP 293. The plan, the tooling, and the rules two blocks earned.";
in
{
  # A string, not a path, for the reason given in ../pathe/default.nix.
  commandText = ''
    ---
    description: ${description} Optionally pulls recent rides and nutrition.
    argument-hint: [notes, a question, and/or "pull the last N days"]
    allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(intervals-icu:*), Bash(weather:*), Bash(nix-shell:*), Bash(python3:*), mcp__plugin_hm_cronometer__get_food_log, mcp__plugin_hm_cronometer__get_daily_nutrition, mcp__plugin_hm_cronometer__get_nutrition_scores, mcp__plugin_hm_cronometer__get_biometrics
    ---

    ${claudeCodeBody}
  '';

  # A directory, as dsh's tool-skill scanner expects: one SKILL.md per subdirectory.
  skills = pkgs.runCommand "dsh-skills" { } ''
    mkdir -p "$out/coach"
    cp ${pkgs.writeText "SKILL.md" ''
      ---
      name: coach
      description: ${description} Use when asked about training, a ride just done, FTP, fuelling, the session log, or whether a quality session should go ahead.
      ---

      # Coaching the winter training block

      ${dshBody}
    ''} "$out/coach/SKILL.md"
  '';
}
