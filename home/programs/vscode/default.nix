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
    enable = lib.mkEnableOption "Enable vscode package";
    useSettings = lib.mkEnableOption "Use Oxey vscode settings";
    useExtensions = lib.mkEnableOption "Use Oxey extensions";
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
    };
  };
}
