{ lib, config, ... }:
let
  cfg = config.kanata;
in
{
  options.kanata = {
    enable = lib.mkEnableOption "enable kanata module";
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
          config = ''
            (defsrc
                grv       1    2    3    4    5    6    7    8    9    0    -    =    bspc
                tab       q    w    e    r    t    y    u    i    o    p    [    ]    ret
                caps      a    s    d    f    g    h    j    k    l    ;    '    \
                lsft 102d z    x    c    v    b    n    m    ,    .    /    rsft
                lctl lmet lalt           spc                 ralt rmet rctl
            )

            (deflayer george
                `    1    2    3    4    5         6    7    8    9    0    [    ]    bspc
                tab  @:;  u    o    f    j         @quk k    l    r    v    /    =    ret
                bspc e    i    a    c    y         d    h    t    n    s    -    \
                @osl .    ,    .    p    g    '    b    m    w    x    z    @osr
                @ocl lmet lalt                spc            @qwt rmet @ocr
            )

            (deflayer qwerty
                grv       1    2    3    4    5    6    7    8    9    0    -    =    bspc
                tab       q    w    e    r    t    y    u    i    o    p    [    ]    ret
                caps      a    s    d    f    g    h    j    k    l    ;    '    \
                lsft \    z    x    c    v    b    n    m    ,    .    /    rsft
                lctl lmet lalt           spc                 @dvk rmet rctl
            )

            (defalias
                grg (layer-switch george)
                qwt (layer-switch qwerty)
                b   (fork S-/ 1 (lsft rsft))
                :;  (fork S-; (unmod ;) (lsft rsft))
                qu  (multi q u)
                Qu  (multi S-q u)
                quk (tap-dance 150 (
                (fork (
                    fork
                    @qu
                    @Qu (lsft rsft))
                    q (lctl rctl))
                q))
                osl (one-shot 500 lsft)
                osr (one-shot 500 rsft)
                ocl (one-shot 500 lctl)
                ocr (one-shot 500 rctl)
            )

            ;; (deflayer sturdy
            ;;   `    1    2    3    4    5         6    7    8    9    0    [    ]    bspc
            ;;   tab  v    m    l    c    p         x    f    o    u    j    /    =    ret
            ;;   bspc s    t    r    d    y         .    n    a    e    i    -    \
            ;;   @osl z    k    @quk g    w    @b   b    h    '    ;    ,    @osr
            ;;   @ocl lmet lalt                spc            @stn rmet @ocr
            ;; )

            ;; (deflayer stronk
            ;;   `    1    2    3    4    5         6    7    8    9    0    [    ]    bspc
            ;;   tab  f    d    l    b    v         j    g    o    u    ,    /    =    ret
            ;;   bspc s    t    r    n    k         y    m    a    e    i    -    \
            ;;   @osl z    @quk x    h    p    @b   w    c    '    @:;  .    @osr
            ;;   @ocl lmet lalt                spc            @cmp rmet @ocr
            ;; )
          '';
        };
      };
    };
  };
}
