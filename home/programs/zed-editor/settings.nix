{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.zed-editor;
in
{
  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
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
        icon_theme = "JetBrains Icons Dark";
        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };
        wrap_guides = [ 100 ];
        preferred_line_length = 100;
        soft_wrap = "preferred_line_length";
        journal = {
          hour_format = "hour24";
        };
        file_types = {
          c = [
            "c"
            "h"
          ];
          Assembly = [ "*.casm" ];
        };
        languages = {
          Assembly = {
            show_edit_predictions = false;
          };
          Markdown = {
            tab_size = 4;
          };
          Nix = {
            tab_size = 2;
            formatter = {
              external = {
                command = "nixfmt";
                args = [ "{buffer_path}" ];
              };
            };
          };
        };
        lsp = {
          rust-analyzer = {
            binary = {
              path = lib.getExe pkgs.rust-analyzer;
              path_lookup = true;
            };
          };
          package-version-server = {
            binary = {
              path = lib.getExe pkgs.package-version-server;
              path_lookup = true;
            };
          };
        };
      };
    };
  };
}
