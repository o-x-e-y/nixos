{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;
  status-line = import ./commands/status-line.nix { inherit pkgs; };

  # Shared with ../dsh, which renders the same body as a skill. See ./coach and
  # ./pathe -- neither is a module any more, each renders one document for both
  # harnesses and is imported here.
  coach = import ./coach { inherit pkgs; };
  pathe = import ./pathe { inherit pkgs; };

  intervals-icu = pkgs.writeShellApplication {
    name = "intervals-icu";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = builtins.readFile ./intervals-icu.sh;
  };
in
{
  # One directory per integration. Each owns its package, its credentials and
  # its own permission entries; the lists merge back into the ones below.
  # ./coach and ./pathe are not modules: they render a document for both
  # harnesses, and the settings that used to come with them live here.
  imports = [
    ./cronometer
    ./intervals-icu
    ./weather
  ];

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
      enableMcpIntegration = true;

      settings = {
        statusLine = status-line;

        model = "opus";
        effortLevel = "xhigh";
        tui = "fullscreen";

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
            "Bash(curl:*)"
            "Bash(intervals-icu:*)"

            # Read-only and unauthenticated: the Pathé API is an open GET and
            # the CLI cannot book a seat, so this allows rather than asks. It
            # moved here from ./pathe when that directory became the document
            # both harnesses read -- a document has no permissions of its own.
            "Bash(pathe:*)"
            "WebFetch"
          ];
          ask = [ ];
          deny = [
            "Bash(cargo publish:*)"
            "Bash(npm publish:*)"
            "Bash(twine upload:*)"

            "Bash(git push --force:*)"
            "Bash(git push -f:*)"
            "Bash(git reset --hard:*)"
            "Bash(git clean -f:*)"

            "Bash(rm -rf:*)"

            "Read(./.env)"
            "Read(**/.env)"
            "Read(**/.env.*)"
            "Read(./secrets/**)"
            "Read(~/.ssh/**)"
            "Read(~/.gnupg/**)"
            "Read(~/.aws/credentials)"
            "Read(**/*.pem)"
            "Read(**/*.key)"
          ];
          defaultMode = "auto";
          additionalDirectories = [
            "~/Repos"
            "~/Documents/fontys"
          ];
        };
      };

      # global CLAUDE.md start of conversation context
      context = ''
        # Environment

        This machine is NixOS. If a package isn't available, run
        `nix-shell -p <package> --run "<command>"` rather than reporting it as missing.
      '';

      agents = {
        typst-writer = ./agents/typst-writer.md;
        comptences = ./agents/comptences.md;
        canvas-submit = ./agents/canvas-submit.md;
      };

      commands = {
        coach = coach.commandText;
        pathe = pathe.commandText;
      };

      plugins.superpowers = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "6fd4507659784c351abbd2bc264c7162cfd386dc";
        sha256 = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
      };
    };

    home.packages = [
      pkgs.claude-monitor
      intervals-icu
    ];
  };
}
