{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.route;
in
{
  options.apps.route = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the route CLI";
    };
  };

  # Options from the route-cli flake's module, kept out of ../claude-code. The
  # binary is wrapped with these, so the key never enters the store. The
  # Cloud project is on the free trial, which can't set a daily quota; the
  # limit stands in for it.
  config = lib.mkIf cfg.enable {
    programs.route = {
      enable = true;
      keyFile = "/run/secrets/routes-api-key";
      limit = {
        requests = 600;
        days = 7;
      };
    };
  };
}
