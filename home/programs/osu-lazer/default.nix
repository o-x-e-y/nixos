{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.osu-lazer;
  osuDir = ".local/share/osu";

  # Runtime-rewritten osu files we persist across machines. Each is seeded
  # copy-if-missing as a WRITABLE copy (never symlinked read-only -- osu must be
  # able to rewrite them), and is inert until its config/ snapshot exists.
  #   client.realm  : keybinds, skins, beatmap index (binary)
  #   input.json    : tablet area/rotation/pressure + screen mapping
  #   framework.ini : window mode, audio device, volumes, renderer, frame sync
  #   game.ini      : gameplay / UI / editor settings
  # NOTE: the only credential anywhere is the login Token in game.ini, which
  # osu-config-backup strips on copy -- so nothing committed carries a secret.
  # The Realm sidecars (client.realm.lock/.note/.management) are transient and
  # intentionally not seeded; Realm regenerates them when it opens client.realm.
  seeds = {
    "client.realm" = ./config/osu-client.realm;
    "input.json" = ./config/osu-input.json;
    "framework.ini" = ./config/osu-framework.ini;
    "game.ini" = ./config/osu-game.ini;
  };

  # Snapshot the live config into this module's config/ (Token stripped from
  # game.ini). Run with no args, or pass a different target dir.
  osuConfigBackup = pkgs.writeShellApplication {
    name = "osu-config-backup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      src="$HOME/${osuDir}"
      dst="''${1:-$HOME/nixos/home/programs/osu-lazer/config}"
      cp -f "$src/client.realm"  "$dst/osu-client.realm"
      cp -f "$src/input.json"    "$dst/osu-input.json"
      cp -f "$src/framework.ini" "$dst/osu-framework.ini"
      # game.ini holds the login Token -- strip it so no credential is committed.
      grep -v '^Token = ' "$src/game.ini" > "$dst/osu-game.ini" || true
      echo "Backed up osu config to $dst (game.ini Token stripped)."
    '';
  };
in
{
  options.apps.osu-lazer = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable osu!lazer";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.osu-lazer-bin
      osuConfigBackup
    ];

    home.activation = lib.concatMapAttrs (
      file: seed:
      lib.optionalAttrs (builtins.pathExists seed) {
        "seedOsu-${lib.replaceStrings [ "." ] [ "-" ] file}" =
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            dest="$HOME/${osuDir}/${file}"
            if [ ! -e "$dest" ]; then
              $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
              $DRY_RUN_CMD cp ${seed} "$dest"
              $DRY_RUN_CMD chmod u+w "$dest"
            fi
          '';
      }
    ) seeds;
  };
}
