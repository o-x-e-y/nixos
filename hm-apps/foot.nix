{ config, lib, pkgs, ... }:
let
  cfg = config.apps.foot;
in
{
  options.apps.foot = {
    enable = lib.mkEnableOption "Enable foot terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.foot ];
    
    programs.foot = {
      enable = true;
      settings = {
        
      };
    };
  };
}
