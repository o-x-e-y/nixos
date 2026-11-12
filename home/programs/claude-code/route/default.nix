{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "route";
  title = "Public transport trips";
  description = "Plan the user's public transport trips in the Netherlands with the route CLI -- when to leave, which trains and buses, whether a plan fits, and the trip back, from Google's timetables. Knows home (Beek en Donk, bus 321/322 from Lieshoutseweg) and the user's cinemas. Puts a trip in Google Calendar only after the user confirms.";
  argumentHint = "[naar <plek> om <tijd> | hoe kom ik bij <film> | terug naar huis na <tijd>]";
  allowedTools = "Bash(route:*), Bash(date:*)";
  body = ./body.md;
}
