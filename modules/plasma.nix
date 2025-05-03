{ config, ... }:
{
  home-manager.users.${config.main-user.username} = {
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
          # {
          # enable = true;
          # leftHanded = false;
          # middleButtonEmulation = false;
          # acceleration = "0.20";
          # accelerationProfile = "none";
          # }
        ];
      };

      # configFile."kglobalshortcutsrc"."KDE Keyboard Layout Switcher" = {
      #     "Next keyboard layout" = "Switch to Next Keyboard Layout=Meta+Space,Meta+Alt+K,Switch to Next Keyboard Layout";
      # };
    };
  };
}
