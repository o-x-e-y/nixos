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
  #
  # The course ids change when a semester gets a new course (`canvas courses`
  # lists them); the personal course stays and gets a module per semester,
  # dragged to the top, so it needs no module id.
  config = lib.mkIf cfg.enable {
    programs.canvas = {
      enable = true;
      url = "https://fontysict.instructure.com";
      apiKeyFile = "/run/secrets/canvas-api-key";
      editor = "codium --wait";
      courses = {
        personal = {
          id = 14809;
          indent = 1;
        };
        general.id = 16040;
      };
      defaults = {
        assignment = "personal";
        delete = "personal";
        modules = "personal";
        outcomes = "personal";
        hand-in = "general";
      };
      feedback.enable = true;
    };
  };
}
