{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.ghostty;
in
{
  options.apps.ghostty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Ghostty terminal emulator";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;

      settings = {
        # Matches the Konsole profile font.
        font-family = "JetBrainsMonoNL Nerd Font Mono";
        font-size = 12;

        # Gruvbox palette ported from the Konsole "vim-dark-hard" scheme.
        theme = "vim-dark-hard";

        # Matches Konsole's RemoveWindowTitleBarAndFrame / disabled menu bar.
        window-decoration = "none";
      };

      # Ported 1:1 from home/programs/konsole/vim-dark-hard.colorscheme.
      themes.vim-dark-hard = {
        palette = [
          "0=#3c3836"
          "1=#cc241d"
          "2=#98971a"
          "3=#d79921"
          "4=#458588"
          "5=#b16286"
          "6=#689d6a"
          "7=#a89984"
          "8=#928374"
          "9=#fb4934"
          "10=#b8bb26"
          "11=#fabd2f"
          "12=#83a598"
          "13=#d3869b"
          "14=#8ec07c"
          "15=#ebdbb2"
        ];
        background = "1d2021";
        foreground = "ebdbb2";
        cursor-color = "ebdbb2";
      };
    };

    # Ctrl+Alt+T launches Ghostty (KDE global shortcut).
    programs.plasma.hotkeys.commands."launch-ghostty" = {
      name = "Launch Ghostty";
      key = "Ctrl+Alt+T";
      command = "${pkgs.ghostty}/bin/ghostty";
    };

    # Make Ghostty the default terminal emulator. Dolphin's "Open Terminal"
    # and other KDE apps launch it via KTerminalLauncherJob, which reads
    # TerminalService (a desktop-file id) from kdeglobals [General].
    programs.plasma.configFile.kdeglobals.General = {
      TerminalApplication = "ghostty";
      TerminalService = "com.mitchellh.ghostty.desktop";
    };
  };
}
