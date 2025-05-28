{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.bash;
in
{
  options.apps.bash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable bash settings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      historyControl = [ "ignoreboth" ]; # ignore both duplicates and space in history
      shellAliases = {
        "ls" = "ls --color=auto";
        "ll" = "ls --color=auto -l";
        "grep" = "grep --color=auto";
        ".." = "cd ..";
        "zed" = "${pkgs.zed-editor}/bin/zeditor";
        "rebuild" = "sudo nixos-rebuild switch --flake ~/nixos#nixos";
      };
    };
  };
}
