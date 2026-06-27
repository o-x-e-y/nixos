{ lib, config, ... }:
let
  cfg = config.modules.opentabletdriver;

  # The tablet area + output mode live declaratively in
  # dotfiles/opentabletdriver/settings.json (captured from a working daemon via
  # `otd savedefaultsettings`). It encodes Absolute Mode with the osu-matched
  # tablet area (56x35mm @ 43,48 -- straight from osu's input.json) mapped to the
  # full display. There is no NixOS option for the tablet area, so seeding OTD's
  # own config file is the standard approach; we copy it in only if missing, so
  # you can still retune live via `otd`/the GUI and keep the change.
  #
  # NOTE: the Display area in that file is 1536x960 -- what X/XWayland reports
  # under 1.25x fractional scaling, NOT the native 1920x1200. If you change
  # display scaling, re-run `otd setdisplayarea ... && otd savedefaultsettings`
  # and re-copy the file into dotfiles/.
  settingsSeed = ./../../dotfiles/opentabletdriver/settings.json;
in
{
  options.modules.opentabletdriver = {
    enable = lib.mkEnableOption "OpenTabletDriver system daemon with osu-matched tablet area";
  };

  config = lib.mkIf cfg.enable {
    # System daemon used for BOTH the desktop and osu. The module also installs
    # udev rules (libusb/hidraw + /dev/uinput access) and blacklists the
    # conflicting `wacom`/`hid-uclogic` kernel modules. Only one process may
    # claim the tablet's USB device, so osu's *bundled* OTD handler must be
    # disabled in-game (Settings -> Input); osu then tracks the daemon's
    # virtual cursor like any other absolute pointer.
    hardware.opentabletdriver.enable = true;
    hardware.opentabletdriver.daemon.enable = true;

    # OTD 0.6.7 queries X (XWayland) for the display and SIGSEGVs if it starts
    # before XWayland is accepting connections (upstream bug: no null-check on
    # the X display). Fix it declaratively, no wrapper script:
    #   * order after the Plasma Wayland session (compositor + XWayland + the
    #     DISPLAY/XAUTHORITY env import) so it almost never races, and
    #   * harden the auto-restart so the residual sub-second race is invisible:
    #     retry forever (no start limit), quickly, and don't dump 8MB cores.
    systemd.user.services.opentabletdriver = {
      after = [ "plasma-workspace-wayland.target" ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        RestartSec = 2;
        LimitCORE = 0;
      };
    };

    # Seed the OTD config copy-if-missing (the daemon reads & may rewrite it).
    systemd.user.tmpfiles.rules = [
      "d %h/.config/OpenTabletDriver 0755 - - - -"
      "C %h/.config/OpenTabletDriver/settings.json 0644 - - - ${settingsSeed}"
    ];
  };
}
