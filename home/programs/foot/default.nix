{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.foot;
in
{
  options.apps.foot = {
    enable = lib.mkEnableOption "Enable foot terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.foot ];

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "Noto Sans Mono:size=12";
          font-bold = "Noto Sans Mono:style=Bold:size=12";
          font-italic = "Noto Sans Mono:style=Italic:size=12";
          font-bold-italic = "Noto Sans Mono:style=Bold Italic:size=12";

          dpi-aware = false;
          pad = "12x12";
          initial-window-mode = "maximized";
        };
        cursor = {
          style = "beam";
          beam-thickness = "1.5";
        };
        colors = {
          background = "282828";
          foreground = "ebdbb2";
          regular0 = "282828"; # black
          regular1 = "cc241d"; # red
          regular2 = "98971a"; # green
          regular3 = "d79921"; # yellow
          regular4 = "458588"; # blue
          regular5 = "b16286"; # magenta
          regular6 = "689d6a"; # cyan
          regular7 = "a89984"; # white
          bright0 = "928374"; # bright black
          bright1 = "fb4934"; # bright red
          bright2 = "b8bb26"; # bright green
          bright3 = "fabd2f"; # bright yellow
          bright4 = "83a598"; # bright blue
          bright5 = "d3869b"; # bright magenta
          bright6 = "8ec07c"; # bright cyan
          bright7 = "ebdbb2"; # bright white
        };
      };
    };
  };
}
