{ lib, ... }:
{
  imports = [
    ./../../home/profiles/cli.nix
  ];

  programs.git.settings.core.editor = lib.mkForce "nano";
  programs.jrnl.settings.editor = lib.mkForce "nano";
  programs.canvas.editor = lib.mkForce "nano";

  programs.tmux = {
    enable = true;
    mouse = true;
    historyLimit = 50000;
  };

  home.stateVersion = "26.11";
}
