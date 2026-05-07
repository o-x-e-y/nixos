{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.vscodium;
in
{
  imports = [
    ./settings.nix
    ./extensions.nix
    ./keybindings.nix
  ];

  options.apps.vscodium = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable vscodium package";
    };
    useSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey vscodium settings";
    };
    useExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey vscodium extensions";
    };
    useKeybindings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey vscodium keybindings";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscodium = {
      enable = true;
    };
  };
}
