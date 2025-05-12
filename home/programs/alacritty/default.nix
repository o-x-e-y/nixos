{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.alacritty;
in
{
  options.apps.alacritty = {
    enable = lib.mkEnableOption "Enable alacritty terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      theme = "gruvbox_material_hard_dark";
      settings = {
        window = {
          decorations = "None";
          startup_mode = "Maximized";
        };
        font = {
          size = 13.0;
        };
        selection = {
          save_to_clipboard = true;
        };
      };
    };
  };
}
