{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.canvas;
in
{
  options.apps.canvas = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Canvas CLIs";
    };
  };

  # The options come from the canvas-cli flake's home-manager module, loaded in
  # ../../../flake.nix; this only sets the values. Same split as ../pathe: the
  # skills that drive it stay in ../claude-code.
  config = lib.mkIf cfg.enable {
    programs.canvas = {
      enable = true;
      url = "https://fontysict.instructure.com";
      apiKeyFile = "/run/secrets/canvas-api-key";
      editor = "codium --wait";
      feedback.enable = true;
    };
  };
}
