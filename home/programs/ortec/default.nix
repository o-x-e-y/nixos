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

  # Options from the ortec-mcp flake's module, kept out of ../claude-code. The
  # binaries are wrapped with these paths, so credentials never enter the
  # store; the company code isn't a secret.
  config = lib.mkIf cfg.enable {
    programs.ortec = {
      enable = true;
      company = "PATHP";
      userFile = "/run/secrets/ortec-email";
      passwordFile = "/run/secrets/ortec-password";
    };
  };
}
