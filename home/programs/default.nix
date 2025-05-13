{ lib, ... }:
{
  imports = [
    ./alacritty
    ./bash
    ./btop
    ./fastfetch
    ./foot
    ./mimeapps
    ./plasma
    ./spotify-player
    ./vscode
    ./zed-editor
  ];
  
  apps = {
    alacritty.enable = lib.mkDefault true;
    bash.enable = lib.mkDefault true;
    btop.enable = lib.mkDefault true;
    fastfetch.enable = lib.mkDefault true;
    foot.enable = lib.mkDefault true;
    spotify-player.enable = lib.mkDefault true;
    vscode = {
      enable = lib.mkDefault true;
      useSettings = lib.mkDefault true;
      useExtensions = lib.mkDefault true;
    };
    zed-editor = {
      enable = lib.mkDefault true;
      useSettings = lib.mkDefault true;
      useKeymaps = lib.mkDefault true;
      useExtensions = lib.mkDefault true;
    };
  };
}
