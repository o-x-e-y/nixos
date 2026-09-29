{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "canvas-submit";
  title = "Handing in on Canvas";
  description = "Use when the user wants to create an assignment on Canvas or hand in a document, usually a compiled Typst PDF, on Canvas.";
  argumentHint = "[assignment name] [path to file]";
  body = ./body.md;
}
