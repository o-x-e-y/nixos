{ config, ... }:
{
  programs.plasma = {
    enable = true;

    workspace = {
      enableMiddleClickPaste = false;
      theme = "breeze-dark";
      colorScheme = "GruvboxColors";
      cursor = {
        theme = "Breeze";
        size = 24;
      };
      # lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "Fluent-purple-dark";
      wallpaper = ./../public/wallpaper.png;
      soundTheme = "ocean";
      splashScreen = {
        theme = "Breeze";
      };
      windowDecorations = {
        library = "org.kde.kwin.aurorae";
        theme = "__aurorae__svg__Utterly-Round-Dark-Solid";
      };
    };

    input = {
      keyboard = {
        layouts = [
          { layout = "us"; }
          {
            layout = "us";
            variant = "dvorak";
          }
        ];
        options = [
          "caps:backspace"
        ];
      };

      mice = [
        {
          enable = true;
          name = "Logitech PRO X Wireless";
          vendorId = "046d";
          productId = "c094";
          acceleration = 0.20;
          accelerationProfile = "none";
        }
        {
          enable = true;
          name = "Logitech USB Receiver";
          vendorId = "046d";
          productId = "c547";
          acceleration = 0.2;
          accelerationProfile = "none";
        }
      ];

      touchpads = [
        {
          enable = true;
          name = "ELAN0676:00 04F3:3195 Touchpad";
          vendorId = "04f3";
          productId = "3195";
          accelerationProfile = "default";
          disableWhileTyping = true;
          leftHanded = false;
          middleButtonEmulation = false;
          naturalScroll = false;
          pointerSpeed = 0;
          tapToClick = true;
        }
      ];
    };

    # configFile."kglobalshortcutsrc"."KDE Keyboard Layout Switcher" = {
    #     "Next keyboard layout" = "Switch to Next Keyboard Layout=Meta+Space,Meta+Alt+K,Switch to Next Keyboard Layout";
    # };
  };
}
