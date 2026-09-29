{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "fontys";
  title = "Fontys documents";
  description = "Use when writing, structuring or reviewing a document or project for Fontys (FHICT), such as school work, a semester project, a portfolio or anything assessed against HBO-i competences.";
  argumentHint = "[document or question]";
  body = ./body.md;
}
