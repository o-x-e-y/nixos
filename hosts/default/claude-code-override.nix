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

  # Prints the `version` + `hash` lines to paste into flake.nix, read off the
  # release the overlay below would fetch. Takes a version, or resolves the
  # newest one when given none. Only worth having while the override is on --
  # with `enable = false` there is nothing to paste into, and turning it on from
  # cold still works the usual way, by rebuilding against a wrong hash and
  # taking the `got:` line.
  claude-hash = pkgs.writeShellApplication {
    name = "claude-hash";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      config.nix.package # nix hash convert
    ];
    text = ''
      version=''${1:-$(curl -fsSL "${baseUrl}/latest")}

      # One manifest covers every platform, and states the checksum as hex.
      checksum=$(
        curl -fsSL "${baseUrl}/$version/manifest.zst.json" \
          | jq -er '.platforms["${platform}"].checksum'
      )

      printf 'version = "%s";\nhash = "%s";\n' \
        "$version" \
        "$(nix hash convert --hash-algo sha256 --to sri "$checksum")"
    '';
  };
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
    environment.systemPackages = [ claude-hash ];

    nixpkgs.overlays = [
      (final: prev: {
        # Releases publish the binary both bare and zstd-compressed. The nixpkgs
        # installPhase unzstds $src straight into $out/bin, so it has to be the
        # .zst -- handing it the bare ELF fails with "unsupported format". The
        # manifest claude-hash reads is the .zst one for the same reason.
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
