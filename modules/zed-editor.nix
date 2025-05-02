{ config, pkgs, ... }:
{
  home-manager.users.${config.main-user.username} = {
    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [ nixd nil ];
      userSettings = {
        show_edit_predictions = true;
        features = {
          edit_prediction_provider = "zed";
        };
        base_keymap = "VSCode";
        ui_font_size = 16;
        buffer_font_size = 15.0;
        # buffer_font_weight = 100;
        ui_font_family = "Noto Sans";
        buffer_font_family = "Noto Sans Mono";
        theme = {
            mode = "system";
            light = "One Light";
            dark = "Gruvbox Dark Hard";
        };
        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };
        wrap_guides = [100];
        preferred_line_length = 100;
        soft_wrap = "preferred_line_length";
        file_types = {
          c = ["c" "h"];
          Assembly = ["*.casm"];
        };
        languages = {
          Assembly = {
            show_edit_predictions = false;
          };
          Markdown = {
            tab_size = 4;
          };
        };
      };
      userKeymaps = [
        {
          context = "Workspace";
          bindings = {
            "ctrl-`" = "workspace::ToggleBottomDock";
            "ctrl-r" = "projects::OpenRecent";
            # "ctrl-:" = "editor::ToggleInlayHints";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl+t" = "workspace::NewTerminal";
          };
        }
        {
          context = "Editor";
          bindings = {
            # "j k": ["workspace::SendKeystrokes", "escape"]
          };
        }
      ];
    };
    
    programs.zed-editor-extensions = {
      enable = true;
      packages = with pkgs.zed-extensions; [
        awk
        bqn
        csharp
        dbml
        dockerfile
        env
        html
        http
        kconfig
        latex
        make
        nix
        python-requirements
        rainbow-csv
        scss
        sql
        toml
        typst
        # xml
      ];
    };
  };
}
