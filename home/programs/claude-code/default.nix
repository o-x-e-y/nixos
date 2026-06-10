{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;
  status-line = import ./commands/status-line.nix { inherit pkgs; };
in
{
  options.apps.claude-code = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Claude Code configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;

      settings = {
        statusLine = status-line;

        permissions = {
          allow = [
            "Bash(git diff:*)"
            "Bash(ls:*)"
            "Bash(bun run:*)"
            "Bash(* --version)"
            "Bash(* --help:*)"
            "Bash(grep:*)"
            "Bash(cat:*)"
            "Bash(cargo:*)"
            "Bash(plantuml:*)"
            "Bash(find:*)"
            "Bash(typst compile:*)"
            "Bash(wasm-pack:*)"
            "Bash(git * log:*)"
            "Grep(*)"
            "Glob(*)"
          ];
          ask = [
            "Bash(curl:*)"
            "WebFetch"
          ];
          deny = [
            "Bash(cargo publish:*)"
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
          defaultMode = "acceptEdits";
          disableBypassPermissionsMode = "disable";
          additionalDirectories = [
            "~/Repos"
            "~/Documents/fontys"
          ];
        };
      };

      agents = {
        typst-writer = ./agents/typst-writer.md;
        comptences = ./agents/comptences.md;
        canvas-submit = ./agents/canvas-submit.md;
      };

      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "obra";
          repo = "superpowers";
          rev = "6fd4507659784c351abbd2bc264c7162cfd386dc";
          sha256 = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
        })
      ];
    };

    home.packages = [
      pkgs.claude-monitor
    ];
  };
}
