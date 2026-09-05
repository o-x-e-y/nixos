{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.wiicompiled;

  configPath = ".local/share/WiiCompiled/Config.toml";

  # The Dolphin profile is the source of truth; the TOML is kept as a fallback
  # for a WiiCompiled without the expression engine (anything up to and
  # including 0.2.27), where nothing can bind a control to an analog trigger.
  gcpadSeed = ./../../../dotfiles/wiicompiled/GCPadNew.ini;
  tomlSeed = ./../../../dotfiles/wiicompiled/controller.toml;

  fromGcpad = pkgs.runCommand "wiicompiled-controller-from-gcpad" { } ''
    ${lib.getExe pkgs.gawk} -f ${./gcpad-to-controller.awk} ${gcpadSeed} > $out
  '';

  controllerBlock = if cfg.inputSource == "gcpad" then fromGcpad else tomlSeed;

  # Config.toml cannot be a home.file symlink: WiiCompiled rewrites it in place
  # from the F10 settings bar, and the installer writes machine-specific paths
  # (dvd_root, retro_rewind_root) into it that must not be clobbered. Seeding it
  # copy-if-missing the way modules/opentabletdriver does would never fire
  # either, since the installer creates the file first. So splice in just the
  # one section we own: drop any existing [controller] block, append ours.
  # Idempotent, and every other section survives untouched.
  spliceController = pkgs.writeShellApplication {
    name = "wiicompiled-apply-controller";
    runtimeInputs = [
      pkgs.gawk
      pkgs.coreutils
    ];
    text = ''
      target="$HOME/${configPath}"
      # Nothing to splice into until `wiicompiled-setup install` has run.
      [ -f "$target" ] || exit 0

      tmp=$(mktemp)
      trap 'rm -f "$tmp" "$tmp.trimmed"' EXIT

      awk '
        /^[[:space:]]*\[controller\][[:space:]]*$/ { skip = 1; next }
        /^[[:space:]]*\[/                          { skip = 0 }
        !skip                                      { print }
      ' "$target" > "$tmp"

      # Collapse the trailing blank lines the removal leaves behind, so
      # repeated activations do not grow the file.
      printf '%s\n\n' "$(cat "$tmp")" > "$tmp.trimmed"
      cat ${controllerBlock} >> "$tmp.trimmed"

      if ! cmp -s "$tmp.trimmed" "$target"; then
        mv "$tmp.trimmed" "$target"
      fi
    '';
  };

  # The reverse trip, mirroring osu-config-backup: pull the live [controller]
  # block back into the repo after tuning bindings in the F10 bar. Only the TOML
  # form round-trips -- the game writes bindings, not the Dolphin profile they
  # were generated from -- so this also switches you off `inputSource = "gcpad"`.
  controllerBackup = pkgs.writeShellApplication {
    name = "wiicompiled-config-backup";
    runtimeInputs = [
      pkgs.gawk
      pkgs.gnugrep
      pkgs.coreutils
    ];
    text = ''
      src="$HOME/${configPath}"
      dst="''${1:-$HOME/nixos/dotfiles/wiicompiled/controller.toml}"

      live=$(awk '
        /^[[:space:]]*\[controller\][[:space:]]*$/ { keep = 1; print; next }
        /^[[:space:]]*\[/                          { keep = 0 }
        keep                                       { print }
      ' "$src")

      if [ -z "$live" ]; then
        echo "No [controller] section in $src -- nothing to back up." >&2
        exit 1
      fi

      # Keep the committed file's prose; replace from the first binding down.
      awk '/^[a-z_]+[[:space:]]*=/ { exit } { print }' "$dst" > "$dst.new"
      printf '%s\n' "$live" | grep -E '^[a-z_]+[[:space:]]*=' >> "$dst.new"
      mv "$dst.new" "$dst"
      echo "Backed up [controller] to $dst."
      echo "Set apps.wiicompiled.inputSource = \"toml\" for this to take effect."
    '';
  };
in
{
  options.apps.wiicompiled = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Manage WiiCompiled's controller bindings from dotfiles/wiicompiled";
    };

    inputSource = lib.mkOption {
      type = lib.types.enum [
        "gcpad"
        "toml"
      ];
      default = "gcpad";
      description = ''
        Which dotfile drives the bindings. "gcpad" converts
        dotfiles/wiicompiled/GCPadNew.ini, which is the only form that can put a
        control on an analog trigger, and needs a WiiCompiled with the input
        expression engine (post-0.2.27). "toml" uses the hand-written
        dotfiles/wiicompiled/controller.toml, which works on any version.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ controllerBackup ];

    home.activation.wiicompiledController = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe spliceController}
    '';
  };
}
