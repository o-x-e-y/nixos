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
  boxd = import ./boxd {
    inherit pkgs;
    inherit (config.apps.boxd) user;
  };
  ledger = import ./ledger { inherit pkgs; };
  fontys = import ./fontys { inherit pkgs; };
  typst-writer = import ./typst-writer { inherit pkgs; };
  canvas-submit = import ./canvas-submit { inherit pkgs; };

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
    ./github
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

        modelSettings = {
          "claude-opus-5".effortLevel = "xhigh";
          "claude-opus-5-5".effortLevel = "high";
          "claude-sonnet-5-5".effortLevel = "high";
          "claude-haiku-5-5".effortLevel = "high";
        };

        tui = "fullscreen";
        remoteControlAtStartup = true;
        cleanupPeriodDays = 180;

        autoMode = import ./auto-mode.nix;

        permissions = {
          allow = [
            "Bash(git diff:*)"
            "Bash(ls:*)"
            "Bash(* --version)"
            "Bash(grep:*)"
            "Bash(cat:*)"
            "Bash(cargo:*)"
            "Bash(plantuml:*)"
            "Bash(find:*)"
            "Bash(typst compile:*)"
            "Bash(wasm-pack:*)"
            "Grep(*)"
            "Glob(*)"
            "Bash(curl:*)"
            "Bash(intervals-icu:*)"

            # Read-only and unauthenticated: the Pathé API is an open GET and
            # the CLI cannot book a seat, so this allows rather than asks. It
            # moved here from ./pathe when that directory became the document
            # both harnesses read -- a document has no permissions of its own.
            "Bash(pathe:*)"

            # Same reasoning as pathe above, and the CLI enforces it rather
            # than promising it: boxd has no authenticated code path at all --
            # no login, no POST -- so the worst a wrong call can do is read a
            # public page. See ../boxd/boxd.py's module docstring.
            "Bash(boxd:*)"

            # Only the read path into the journal. The wrapper rejects every
            # flag but jrnl's filters after --json, and jrnl never writes with
            # --format set, so this cannot add, edit or delete an entry. Plain
            # `ledger` writes, and falls to the soft_deny in ./auto-mode.nix.
            "Bash(ledger --json:*)"

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

        Use YAGNI principles when programming. Don't add comments unless the
        reason for something isn't clear from the code, for example when the
        obvious fix would break something. Explain other decisions in the
        commit message instead.

        For jobs that are mostly reading or searching (lots of files, logs or
        docs to answer one question), use a subagent with model sonnet and ask
        it for a short answer. Do everything else yourself.
      '';

      commands = {
        coach = coach.commandText;
        pathe = pathe.commandText;
        boxd = boxd.commandText;
        ledger = ledger.commandText;
        fontys = fontys.commandText;
        typst-writer = typst-writer.commandText;
        canvas-submit = canvas-submit.commandText;
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
