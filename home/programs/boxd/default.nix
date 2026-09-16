{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.boxd;

  # curl_cffi rather than requests, and the reason is not preference: Letterboxd
  # fronts Cloudflare, which challenges plain curl's TLS handshake on roughly
  # half of all requests. curl_cffi replays Chrome's fingerprint. Without it
  # every other page is "Just a moment..." behind a 403, so there is no lighter
  # dependency to fall back to -- see the module docstring in ./boxd.py.
  python = pkgs.python313.withPackages (ps: [ ps.curl-cffi ]);

  boxd = pkgs.runCommand "boxd"
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

      # The interpreter is named outright rather than left to patchShebangs:
      # that hook only rewrites a shebang it can resolve on the build PATH, and
      # nothing here puts a python there, so `#!/usr/bin/env python3` would
      # survive into $out and fail at run time on a machine without one. This
      # also guarantees the interpreter is the curl_cffi-carrying python above
      # rather than whichever python happens to be first on PATH.
      substituteInPlace "$out/bin/boxd" \
        --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3'

      # --set-default, not --set: the declarative username is a default, not a
      # cage. `BOXD_USER=someone boxd profile` still works, and so does --user,
      # which is what makes looking at a friend's profile a one-off rather than
      # a rebuild.
      wrapProgram "$out/bin/boxd" \
        --set-default BOXD_USER ${lib.escapeShellArg cfg.user} \
        --set-default BOXD_TTL ${toString cfg.cacheTtl} \
        ${lib.optionalString (cfg.cacheDir != null)
          "--set-default BOXD_CACHE ${lib.escapeShellArg cfg.cacheDir}"}
    '';
in
{
  # Shaped like ../pathe: the package lives here rather than under
  # ../claude-code/boxd because boxd is a tool Claude also uses, not the other
  # way round -- hanging it off `apps.claude-code.enable` would take it off the
  # system whenever that is turned off. The document both harnesses read lives
  # in ../claude-code/boxd, which is not a module for the same reason ../pathe
  # is not one.
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
      default = null;
      example = "/home/oxey/.cache/boxd";
      description = ''
        Where to cache fetched pages. Null uses $XDG_CACHE_HOME/boxd, which is
        almost always what you want.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ boxd ];
  };
}
