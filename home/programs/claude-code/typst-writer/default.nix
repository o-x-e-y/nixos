{ pkgs }:
import ../shared-skill.nix { inherit pkgs; } {
  name = "typst-writer";
  title = "Writing Typst documents";
  description = "Use when writing, editing or compiling Typst (.typ) documents, reports or documentation, including requirement tables and PlantUML diagrams in them.";
  allowedTools = "Bash(typst:*), Bash(plantuml:*)";
  body = ./body.md;
}
