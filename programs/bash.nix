{ config, pkgs, ... }:
{
  home-manager.users.${config.main-user.username} = {
    programs.bash = {
      enable = true;
      historyControl = [ "ignoreboth" ]; # ignore both duplicates and space in history
      shellAliases = {
        "ls" = "ls --color=auto";
        "ll" = "ls --color=auto -l";
        "grep" = "grep --color=auto";
        ".." = "cd ..";
        "zed" = "${pkgs.zed-editor}/bin/zeditor";
      };
    };
  };
}
