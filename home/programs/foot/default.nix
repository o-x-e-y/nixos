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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable foot terminal emulator";
    };
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
          regular0 = "282828";
          regular1 = "cc241d";
          regular2 = "98971a";
          regular3 = "d79921";
          regular4 = "458588";
          regular5 = "b16286";
          regular6 = "689d6a";
          regular7 = "a89984";
          bright0 = "928374";
          bright1 = "fb4934";
          bright2 = "b8bb26";
          bright3 = "fabd2f";
          bright4 = "83a598";
          bright5 = "d3869b";
          bright6 = "8ec07c";
          bright7 = "ebdbb2";
        };
      };
    };
  };
}
