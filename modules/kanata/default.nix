{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.kanata;
in
{
  options.modules.kanata = {
    enable = lib.mkEnableOption "Enable kanata module";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kanata ];

    services.kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          devices = [
            # `ls /dev/input/by-path/` to find these
            "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
            "/dev/input/by-path/pci-0000:64:00.3-usb-0:1:1.1-event-kbd"
          ];
          extraDefCfg = "process-unmapped-keys yes";
          config = builtins.readFile ./../../dotfiles/kanata/kanata.kbd;
        };
      };
    };
  };
}
