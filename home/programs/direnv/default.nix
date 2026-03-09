{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.direnv;
in
{
  options.apps.direnv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable direnv configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      config = {
        strict_env = true;
        warn_timeout = "30s";
        whitelist = {
          prefix = [
            "~/Repos"
          ];
        };
      };
    };
  };
}
