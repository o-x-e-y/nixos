{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable = lib.mkEnableOption "enable user module";
    username = lib.mkOption {
      default = "oxey";
      description = ''
        main user
      '';
    };
    profile-picture = lib.mkOption {
      default = null;
      example = ./path/to/profile-picture.jpg;
      type = lib.types.path;
      description = ''
        Path to the user's profile picture.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.username} = {
      isNormalUser = true;
      initialPassword = "waddahell";
      shell = pkgs.bash;
    };
  };
}
