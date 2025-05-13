{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.btop;
in
{
  options.apps.btop = {
    enable = lib.mkEnableOption "Enable btop";
  };
  
  config = lib.mkIf cfg.enable {    
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "gruvbox_dark";
        theme_background = true;
        truecolor = true;
        rounded_corners = true;
        graph_symbol = "block";
      };
    };
  };
}
