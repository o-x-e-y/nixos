{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.claudeCodeOverride;
  baseUrl = "https://downloads.claude.ai/claude-code-releases";
  platform = "linux-x64";
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
      description = "SRI hash of the ${platform} claude.zst for the given version";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        # Releases publish the binary both bare and zstd-compressed. The nixpkgs
        # installPhase unzstds $src straight into $out/bin, so it has to be the
        # .zst -- handing it the bare ELF fails with "unsupported format". The
        # manifest claude-hash (home/programs/claude-code) reads is the .zst one
        # for the same reason.
        claude-code = prev.claude-code.overrideAttrs (_old: {
          version = cfg.version;
          src = prev.fetchurl {
            url = "${baseUrl}/${cfg.version}/${platform}/claude.zst";
            hash = cfg.hash;
          };
        });
      })
    ];
  };
}
