{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.ortec;
in
{
  options.apps.ortec = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the ortec CLI";
    };
  };

  # The options come from the ortec-mcp flake's home-manager module, loaded in
  # ../../../flake.nix; this only sets the values. Same split as ../pathe: the
  # CLI is the user's tool first and Claude's second. The module wraps the
  # binaries with these paths, so the credentials never enter the store. The
  # company code is not a secret, so it sits here rather than in sops.
  config = lib.mkIf cfg.enable {
    programs.ortec = {
      enable = true;
      company = "PATHP";
      userFile = "/run/secrets/ortec-email";
      passwordFile = "/run/secrets/ortec-password";
    };
  };
}
