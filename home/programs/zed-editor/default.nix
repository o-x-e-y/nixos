{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.zed-editor;
in
{
  imports = [
    ./extensions.nix
    ./keymaps.nix
    ./settings.nix
  ];

  options.apps.zed-editor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Zed Editor";
    };
    useSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey settings";
    };
    useKeymaps = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey keymaps";
    };
    useExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Oxey extensions";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
    };
  };
}
