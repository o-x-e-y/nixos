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
    enable = lib.mkEnableOption "Enable Zed Editor";
    useSettings = lib.mkEnableOption "Use Oxey settings";
    useKeymaps = lib.mkEnableOption "Use Oxey keymaps";
    useExtensions = lib.mkEnableOption "Use Oxey extensions";
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
    };
  };
}
