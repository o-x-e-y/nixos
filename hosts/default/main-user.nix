{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.mainUser;
in
{
  options.mainUser = {
    enable = lib.mkEnableOption "enable user module";
    username = lib.mkOption {
      default = "oxey";
      description = ''
        main user
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.username} = {
      isNormalUser = true;
      description = "main user";
      initialPassword = "waddahell";
      shell = pkgs.bash;
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "video"
        "render"
      ];
    };
  };
}
