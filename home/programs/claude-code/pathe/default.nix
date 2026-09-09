{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.claude-code;

  # The package and the favourites config live in ../../pathe; this module owns
  # only the agent-facing surface.
  #
  # A CLI and not an MCP server, for the reason ../weather spells out: the Pathé
  # API is an unauthenticated GET and every bit of consolidation the tool does --
  # the matrix fanout, the dub and kids filters, the Markdown rendering -- is
  # deterministic and needs no model in the loop. A server would load tool
  # schemas into every session to buy nothing. The slash command below is the
  # natural-language front door; `pathe --help` is the reference for both a
  # person and an agent.
  description = "What is playing at Pathé -- a day's programme, when a given film plays, and the arthouse (In the Picture), Pride Night and classics strands. Read-only from the public Pathé API; it cannot book a seat.";
in
{
  config = lib.mkIf cfg.enable {
    # Lists merge across modules, so this appends to the allowlist in
    # ../default.nix rather than replacing it. Read-only and unauthenticated:
    # there is no secret to declare and nothing here can order a seat, so this
    # allows rather than asks.
    programs.claude-code.settings.permissions.allow = [ "Bash(pathe:*)" ];

    programs.claude-code.commands.pathe = ''
      ---
      description: ${description}
      argument-hint: [wat draait er vanavond | wanneer draait <film> | arthouse | pride | classics]
      allowed-tools: Bash(pathe:*), Bash(date:*)
      ---

      ${builtins.readFile ./command.md}
    '';
  };
}
