{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.libreoffice;
in
{
  options.apps.libreoffice = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable libreoffice";
    };
    
    package = lib.mkPackageOption pkgs "libreoffice-fresh" { };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [
          hunspellDicts.en_US
          hunspellDicts.nl_NL
        ]
      '';
      description = ''
        Additional LibreOffice-related packages to install when LibreOffice is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ] ++ cfg.extraPackages;
  };
}
