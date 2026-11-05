{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.boxd;

  # curl_cffi, not requests: Cloudflare challenges plain TLS on Letterboxd (see
  # ./boxd.py's docstring).
  python = pkgs.python313.withPackages (ps: [ ps.curl-cffi ]);

  boxd =
    pkgs.runCommand "boxd"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta = {
          description = "Read-only Letterboxd for a public profile";
          mainProgram = "boxd";
        };
      }
      ''
        mkdir -p "$out/bin"
        install -Dm755 ${./boxd.py} "$out/bin/boxd"

        # Not left to patchShebangs: nothing puts a python on the build PATH,
        # so it would leave `#!/usr/bin/env python3` in place.
        substituteInPlace "$out/bin/boxd" \
          --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3'

        # --set-default so `BOXD_USER=someone boxd` still works.
        wrapProgram "$out/bin/boxd" \
          --set-default BOXD_USER ${lib.escapeShellArg cfg.user} \
          --set-default BOXD_TTL ${toString cfg.cacheTtl} \
          ${lib.optionalString (
            cfg.cacheDir != null
          ) "--set-default BOXD_CACHE ${lib.escapeShellArg cfg.cacheDir}"}
      '';
in
{
  # Not under ../claude-code, so it stays installed with claude-code off.
  options.apps.boxd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the boxd Letterboxd CLI";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "oxey";
      example = "davidehrlich";
      description = ''
        Letterboxd username every command defaults to. Overridable per
        invocation with `--user`, or per shell with `$BOXD_USER`.
      '';
    };

    cacheTtl = lib.mkOption {
      type = lib.types.ints.positive;
      default = 6 * 60 * 60;
      description = ''
        How long, in seconds, a fetched list stays fresh. Film metadata is
        cached far longer regardless (30 days), since a director does not
        change; this governs the things that do, like a watchlist.
      '';
    };

    cacheDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${config.home.homeDirectory}/.cache/boxd";
      defaultText = lib.literalExpression ''"\${config.home.homeDirectory}/.cache/boxd"'';
      example = "/var/tmp/boxd";
      description = ''
        Where to cache fetched pages. Set to an absolute path by default rather
        than left null: null means "whatever $BOXD_CACHE says", and a harness
        that runs boxd as a tool may set that to a relative scratch name, which
        used to resolve against the working directory and leave the cache in
        whichever repository the tool was called from. Naming it here makes the
        location a property of the configuration instead of the caller.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ boxd ];
  };
}
