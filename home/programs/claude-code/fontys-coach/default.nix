{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "fontys-coach";
  title = "A Fontys coach reading your work";
  description = "Use when the user wants a Fontys (FHICT) document, portfolio or project critiqued the way a semester coach would, is preparing for a coach meeting or feedback moment, or asks what a coach will ask about their work.";
  argumentHint = "[document(s)] [focus or meeting context]";
  body = ./body.md;
}
