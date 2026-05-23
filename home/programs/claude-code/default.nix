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
          ];
        };
      };

      agents = {
        typst-writer = ./agents/typst-writer.md;
        comptences = ./agents/comptences.md;
        canvas-submit = ./agents/canvas-submit.md;
      };
    };

    home.packages = [
      pkgs.claude-monitor
    ];
  };
}
