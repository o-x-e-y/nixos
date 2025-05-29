{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.btop;
in
{
  options.apps.libreoffice = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable libreoffice";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      libreoffice-fresh
      hunspellDicts.en_GB-ise
      hunspellDicts.nl_NL
    ];
  };
}
