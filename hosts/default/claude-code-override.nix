{
  lib,
  config,
  ...
}:
let
  cfg = config.claudeCodeOverride;
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
in
{
  options.claudeCodeOverride = {
    enable = lib.mkEnableOption "claude-code version override (use when nixpkgs lags behind)";

    version = lib.mkOption {
      type = lib.types.str;
      description = "claude-code version to pin";
    };

    hash = lib.mkOption {
      type = lib.types.str;
      description = "SRI hash of the linux-x64 binary for the given version";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        claude-code = prev.claude-code.overrideAttrs (_old: {
          version = cfg.version;
          src = prev.fetchurl {
            url = "${baseUrl}/${cfg.version}/linux-x64/claude";
            hash = cfg.hash;
          };
        });
      })
    ];
  };
}
