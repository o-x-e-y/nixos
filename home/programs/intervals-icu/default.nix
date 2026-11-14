{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.intervals-icu;

  intervals-icu = pkgs.writeShellApplication {
    name = "intervals-icu";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = builtins.readFile ./intervals-icu.sh;
  };
in
{
  options.apps.intervals-icu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the intervals-icu CLI";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ intervals-icu ];
  };
}
