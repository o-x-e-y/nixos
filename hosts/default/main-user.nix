{ lib, config, pkgs, ... }:
let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable = lib.mkEnableOption "enable user module";
    userName = lib.mkOption {
      default = "oxey";
      description = ''
        oxey
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      initialPassword = "waddahell";
      description = "oxey";
      shell = pkgs.bash;
    };
  };
}
