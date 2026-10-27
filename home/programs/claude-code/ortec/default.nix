{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "ortec";
  title = "The user's work schedule";
  description = "The user's work schedule at Pathé (ORTEC Employee Self Service) -- their shifts, who they can swap a shift with, sending or answering a swap request, and requesting time off. Changes to the schedule are previewed and only sent once the user confirms.";
  argumentHint = "[wanneer werk ik | ruil <datum> | accepteer ruil <datum> | vrij <datum>]";
  # The reads only. A write without --yes is a preview, but the prefix cannot
  # tell the two apart, so the write commands are left to ask.
  allowedTools = "Bash(ortec shifts:*), Bash(ortec swaps:*), Bash(ortec swap-candidates:*), Bash(ortec leaves:*), Bash(ortec leave-types:*), Bash(ortec working-with:*), Bash(ortec --help), Bash(date:*)";
  body = ./body.md;
}
