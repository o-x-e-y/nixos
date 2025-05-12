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
    enable = lib.mkEnableOption "Enable bash package";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bash ];
    
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
