{ config, lib, ... }:
{
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
}
