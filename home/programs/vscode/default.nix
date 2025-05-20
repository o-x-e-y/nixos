{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.vscode;
in
{
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  options.apps.vscode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable vscode package";
    };
    useSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey vscode settings";
    };
    useExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey extensions";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
    };
  };
}
