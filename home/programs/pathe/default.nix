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

  # Options from the pathe-cli flake's module. Not under ../claude-code, so it
  # stays installed with claude-code off.
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
