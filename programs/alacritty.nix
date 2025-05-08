{ config, lib, ... }:
  let
    cfg = config.programs.alacritty;
  in
{
  options.programs.alacritty = {
    enable = lib.mkEnableOption "Enable Alacritty terminal emulator";
  };
  
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.main-user.username} = {
        programs.alacritty = {
        enable = true;
        theme = "gruvbox_material_hard_dark";
        # settings.general.import = [ pkgs.alacritty-theme.gruvbox_material_hard_dark ];
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
          debug = {
            render_timer = true;
          };
        };
      };
    };
  };
}
