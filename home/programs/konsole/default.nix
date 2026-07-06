{
  config,
  lib,
  mainUser,
  ...
}:
let
  cfg = config.apps.git;
  username = mainUser.username;
in
{
  options.apps.konsole = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Konsole settings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.konsole = {
      enable = true;
      customColorSchemes = {
        gruvbox-material-hard-dark = ./gruvbox-material-hard-dark.colorscheme;
        gruvbox-dark-hard = ./gruvbox-dark-hard.colorscheme;
        vim-dark-hard = ./vim-dark-hard.colorscheme;
      };
      defaultProfile = username;

      profiles."${username}" = {
        colorScheme = "vim-dark-hard";
        font = {
          name = "JetBrainsMonoNL Nerd Font Mono";
          size = 12;
        };
        extraConfig = {
          MainWindow = {
            MenuBar = "Disabled";
          };
          KonsoleWindow = {
            AllowMenuAccelerators = true;
            RemoveWindowTitleBarAndFrame = true;
          };
          SearchSettings = {
            SearchRegExpression = true;
          };
          Scrolling = {
            HistorySize = 5000;
          };
        };
      };
    };
  };
}
