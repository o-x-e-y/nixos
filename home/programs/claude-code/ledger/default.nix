{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "ledger";
  title = "The user's work ledger";
  description = "Use when the user asks what they did, worked on or learned over a period, or wants documentation, a report, a study log or another write-up built from their ledger or jrnl entries.";
  argumentHint = "[what to write] [project or period]";
  body = ./body.md;
}
