{ config, ... }:
{
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
}
