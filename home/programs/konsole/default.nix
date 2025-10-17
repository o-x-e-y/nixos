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
      customColorSchemes.gruvbox-material-hard-dark = ./gruvbox-material-hard-dark.colorscheme;
      defaultProfile = username;

      profiles."${username}" = {
        colorScheme = "gruvbox-material-hard-dark";
        font = {
          name = "courier-prime";
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
