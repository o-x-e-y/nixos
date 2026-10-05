{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.ledger;

  ledger = pkgs.writeShellApplication {
    name = "ledger";
    runtimeInputs = [
      config.programs.jrnl.package
      pkgs.git
    ];
    text = builtins.readFile ./ledger.sh;
  };

  journalDir = "${config.xdg.dataHome}/jrnl";

  ledgerBackup = pkgs.writeShellApplication {
    name = "ledger-backup";
    runtimeInputs = [
      pkgs.gawk
      pkgs.git
      pkgs.openssh
    ];
    text = builtins.readFile ./ledger-backup.sh;
  };
in
{
  options.apps.ledger = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable ledger, a jrnl wrapper that tags entries with the current project";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ ledger ];

    systemd.user.services.ledger-backup = {
      Unit.Description = "Commit and push the jrnl ledger";
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe ledgerBackup} ${journalDir}";
      };
    };

    systemd.user.paths.ledger-backup = {
      Unit.Description = "Back up the jrnl ledger when it changes";
      Path.PathChanged = "${journalDir}/journal.txt";
      Install.WantedBy = [ "default.target" ];
    };

    # Retries pushes that failed offline, and catches writes that landed while
    # the service was already running, which the path unit doesn't queue
    systemd.user.timers.ledger-backup = {
      Unit.Description = "Daily jrnl ledger backup";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    # jrnl only rewrites its config when a key is missing or the version differs,
    # so a complete config pinned to the package version can stay read-only
    programs.jrnl.enable = true;
    programs.jrnl.settings = {
      version = "v${config.programs.jrnl.package.version}";
      journals.default.journal = "${config.xdg.dataHome}/jrnl/journal.txt";
      editor = "zeditor --wait";
      encrypt = false;
      template = false;
      default_hour = 9;
      default_minute = 0;
      timeformat = "%F %R";
      tagsymbols = "@+";
      highlight = true;
      linewrap = 79;
      indent_character = "|";
      colors = {
        body = "none";
        date = "none";
        tags = "none";
        title = "none";
      };
    };
  };
}
