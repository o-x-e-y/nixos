{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.pathe;
in
{
  options.apps.pathe = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the pathe CLI";
    };
  };

  # The options come from the pathe-cli flake's home-manager module, loaded in
  # ../../../flake.nix; this only sets the values. The package lives here rather
  # than in claude-code/pathe because pathe is a tool that Claude also uses, not
  # the other way round -- hanging it off `apps.claude-code.enable` would take
  # it off the system whenever that is turned off.
  config = lib.mkIf cfg.enable {
    programs.pathe = {
      enable = true;
      favorites = [
        "pathe-helmond"
        "pathe-eindhoven"
        "pathe-tilburg-centrum"
        "pathe-tilburg-stappegoor"
      ];
    };
  };
}
