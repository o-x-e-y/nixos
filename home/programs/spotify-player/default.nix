{ config, lib, ... }:
let
  cfg = config.apps.spotify-player;
in
{
  options.apps.spotify-player = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable spotify-player module";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.spotify-player = {
      enable = true;
      settings = {
        # theme = "tokyonight";
        # notify_format = { summary = "{track}"; body = "{artists}"; };
        device = {
          volume = 55;
          normalization = true;
          autoplay = true;
        };
      };
    };
  };
}
