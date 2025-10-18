{
  config,
  lib,
  mainUser,
  ...
}:
let
  cfg = config.apps.git;
in
{
  options.apps.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable git settings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "${mainUser.username}";
      userEmail = "lucoerlemans37@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
        credential.helper = "store";
        core.editor = "code --wait";
        merge.ff = false;
      };
    };
  };
}
