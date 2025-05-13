{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.git;
in
{
  options.apps.git = {
    enable = lib.mkEnableOption "Enable git settings";
  };
  
  config = lib.mkIf cfg.enable {    
    programs.git = {
      enable = true;
      userName = "oxey";
      userEmail = "lucoerlemans37@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
