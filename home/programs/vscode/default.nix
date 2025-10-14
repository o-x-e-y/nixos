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
    ./keybindings.nix
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
    useKeybindings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey keybindings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
    };
  };
}
