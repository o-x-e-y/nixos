{ lib, config, ... }:
let
  cfg = config.modules.kanata;
in
{
  options.modules.kanata = {
    enable = lib.mkEnableOption "Enable kanata module";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "uinput" ];

    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    users.groups.uinput = { };

    systemd.services.kanata-internalKeyboard.serviceConfig = {
      SupplementaryGroups = [
        "input"
        "uinput"
      ];
    };

    services.kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          devices = [
            # Replace the paths below with the appropriate device paths for your setup.
            # Use `ls /dev/input/by-path/` to find your keyboard devices.
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
