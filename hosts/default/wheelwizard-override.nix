# Mario Kart Wii: WheelWizard + Dolphin + WiiCompiled, which are one setup
# rather than three alternatives. See ./mario-kart-wii.md for how they fit
# together, what the game image has to be, and the caveats.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.wheelwizardOverride;
  baseUrl = "https://github.com/TeamWheelWizard/WheelWizard/releases/download";
  wiicompiledBaseUrl = "https://github.com/patchzyy/Wiicompiled/releases/download";
in
{
  options.wheelwizardOverride = {
    enable = lib.mkEnableOption "wheelwizard version override (use when nixpkgs lags behind)";

    version = lib.mkOption {
      type = lib.types.str;
      description = "WheelWizard version to pin, i.e. the release tag without its leading `v`";
    };

    hash = lib.mkOption {
      type = lib.types.str;
      description = "SRI hash of the WheelWizard_Linux release asset for the given version";
    };

    dolphin = {
      version = lib.mkOption {
        type = lib.types.str;
        description = "dolphin-emu version to pin, i.e. the release tag verbatim";
      };

      hash = lib.mkOption {
        type = lib.types.str;
        description = "SRI hash of the dolphin-emu source tree for the given version";
      };
    };

    wiicompiled = {
      version = lib.mkOption {
        type = lib.types.str;
        description = "WiiCompiled version to pin, i.e. the release tag without its leading `v`";
      };

      hash = lib.mkOption {
        type = lib.types.str;
        description = "SRI hash of the WiiCompiled-Setup-x86_64.AppImage asset for the given version";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # WheelWizard only installs and launches Retro Rewind; Dolphin is what
    # actually runs the game, so the two are pinned and installed together.
    # WiiCompiled rides along because it consumes what the pair produces: its
    # --retro-dir wants the RetroRewind6 folder WheelWizard installs under
    # Dolphin's user directory.
    environment.systemPackages = [
      pkgs.dolphin-emu
      pkgs.wiicompiled
    ];

    # The package ships $out/etc/udev/rules.d/51-usb-device.rules, which is what
    # lets Dolphin reach a GameCube controller adapter or a real Wiimote without
    # root. It does nothing unless udev is pointed at the package.
    services.udev.packages = [ pkgs.dolphin-emu ];

    nixpkgs.overlays = [
      (final: prev: {
        # Unlike the nixpkgs package this does not build from source. Doing that
        # means keeping a regenerated NuGet lockfile in step with upstream (and
        # since 2.5.0, with .NET 10), whereas the release asset only needs a new
        # version + hash here -- the same deal as ./claude-code-override.nix.
        wheelwizard =
          let
            # Releases ship one self-contained single-file binary: the runtime,
            # the managed assemblies and every native library sit bundled behind
            # the apphost, which finds them through absolute file offsets baked
            # in at publish time. patchelf shifts those offsets, so the usual
            # autoPatchelfHook repackaging dies at startup with "Arithmetic
            # overflow while reading bundle". The binary has to stay byte for
            # byte intact, which rules out patching its /lib64 interpreter and
            # leaves an FHS sandbox as the way to satisfy it -- the native
            # libraries it unpacks into a temp dir at runtime are equally
            # unpatchable, and resolve against the sandbox too.
            binary = prev.runCommand "wheelwizard-bin-${cfg.version}" { } ''
              install -Dm755 ${
                prev.fetchurl {
                  url = "${baseUrl}/v${cfg.version}/WheelWizard_Linux";
                  hash = cfg.hash;
                }
              } $out/bin/WheelWizard
            '';

            fhsEnv = prev.buildFHSEnv {
              name = "wheelwizard-fhs";
              runScript = "${binary}/bin/WheelWizard";

              # /etc/ssl/certs, /etc/fonts and /run come from the host, so TLS,
              # system fonts and the GPU driver need nothing declared here.
              targetPkgs =
                pkgs: with pkgs; [
                  icu # .NET globalization
                  openssl # .NET crypto and TLS
                  zlib # System.IO.Compression.Native
                  fontconfig
                  freetype
                  libglvnd # libGL, for Avalonia's renderer
                  xdg-utils # the in-app "open folder"/"open link" buttons

                  libx11
                  libxcursor
                  libxext
                  libxi
                  libxrandr
                  libxrender
                  libice
                  libsm
                ];
            };
          in
          prev.stdenvNoCC.mkDerivation {
            pname = "wheelwizard";
            version = cfg.version;

            dontUnpack = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              ln -s ${fhsEnv}/bin/wheelwizard-fhs $out/bin/WheelWizard

              # The release assets are the bare binary, so the desktop entries
              # and icon come from the nixpkgs package's source instead. They
              # only reference `WheelWizard` on PATH, so they stay valid across
              # versions even while this pin runs ahead of nixpkgs.
              install -Dm444 -t $out/share/applications \
                ${prev.wheelwizard.src}/Flatpak/io.github.TeamWheelWizard.WheelWizard.desktop \
                ${prev.wheelwizard.src}/Flatpak/io.github.TeamWheelWizard.WheelWizard-url-handler.desktop

              install -Dm444 ${prev.wheelwizard.src}/Flatpak/io.github.TeamWheelWizard.WheelWizard.png \
                $out/share/icons/hicolor/256x256/apps/io.github.TeamWheelWizard.WheelWizard.png

              runHook postInstall
            '';

            meta = {
              description = "WheelWizard, Retro Rewind Launcher";
              homepage = "https://github.com/TeamWheelWizard/WheelWizard";
              license = lib.licenses.gpl3Only;
              mainProgram = "WheelWizard";
              platforms = [ "x86_64-linux" ];
              sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            };
          };

        # 2606a is a security release: it hardens Dolphin against malicious game
        # files and NetPlay peers -- two GHSA advisories plus bounds checks in
        # the GCZ, DOL and ELF readers and the NetPlay LZO decompressor. Version
        # and hash are the whole of nixpkgs' own 2606 -> 2606a bump, so unlike
        # wheelwizard above this stays a plain overrideAttrs and still builds
        # from source; drop the pin once the flake's nixpkgs catches up.
        dolphin-emu = prev.dolphin-emu.overrideAttrs (_old: {
          version = cfg.dolphin.version;

          src = prev.fetchFromGitHub {
            owner = "dolphin-emu";
            repo = "dolphin";
            tag = cfg.dolphin.version;
            hash = cfg.dolphin.hash;

            # Dolphin vendors its externals as submodules, and stamps the build
            # with the commit it came from -- the package's preConfigure feeds
            # that COMMIT file to cmake, so the fetch has to produce it.
            fetchSubmodules = true;
            leaveDotGit = true;
            postFetch = ''
              pushd $out
              git rev-parse HEAD 2>/dev/null >$out/COMMIT
              find $out -name .git -print0 | xargs -0 rm -rf
              popd
            '';
          };
        });

        # WiiCompiled statically recompiles Mario Kart Wii to a native binary --
        # no emulator, no PowerPC at runtime. That makes this a toolchain
        # wrapper rather than a game: the setup translates *your* PAL RMCP01
        # disc to C++ and compiles it, so the product lands in
        # $XDG_DATA_HOME/WiiCompiled and never in the store.
        #
        # WheelWizard cannot drive it here. Recomp mode is gated behind
        # OperatingSystem.IsWindows() in SettingsManager.IsRecompModeActive(),
        # the settings section is hidden off-Windows, and the recomp services
        # are never registered at all -- which is why Dolphin above stays, and
        # why this is driven from the command line instead.
        wiicompiled =
          let
            bundle = prev.appimageTools.extract {
              pname = "wiicompiled-setup";
              version = cfg.wiicompiled.version;
              src = prev.fetchurl {
                url = "${wiicompiledBaseUrl}/v${cfg.wiicompiled.version}/WiiCompiled-Setup-x86_64.AppImage";
                hash = cfg.wiicompiled.hash;
              };
            };

            # The AppImage carries its own clang/lld/cmake/ninja, built against a
            # glibc distro: lld needs libicui18n.so.70, and clang looks for
            # crtbeginS.o and -lgcc in a GCC sysroot no FHS tree here provides,
            # so CMake's compiler test fails before a line of the game builds.
            # Nixpkgs' toolchain just works -- its clang wrapper already knows
            # where its crt objects and libgcc are. local-build.sh also picks up
            # llvm-ar/llvm-ranlib from whatever directory --cc lives in, so
            # these have to sit together rather than being passed as bare paths.
            toolchain = prev.runCommand "wiicompiled-toolchain" { } ''
              mkdir -p $out/bin
              ln -s ${prev.clang}/bin/clang      $out/bin/clang
              ln -s ${prev.clang}/bin/clang++    $out/bin/clang++
              ln -s ${prev.lld}/bin/ld.lld       $out/bin/ld.lld
              ln -s ${prev.llvm}/bin/llvm-ar     $out/bin/llvm-ar
              ln -s ${prev.llvm}/bin/llvm-ranlib $out/bin/llvm-ranlib
              ln -s ${prev.cmake}/bin/cmake      $out/bin/cmake
              ln -s ${prev.ninja}/bin/ninja      $out/bin/ninja
            '';

            # Reimplements the AppImage's AppRun, which cannot be reused as-is:
            # it stages the bundled workspace with `cp -r` out of $HERE, and
            # $HERE is a store path here, so every copy lands read-only and the
            # next version's `rm -rf` of it fails. Same staging plus a chmod.
            dispatch = prev.writeShellScriptBin "wiicompiled-dispatch" ''
              set -euo pipefail

              root="''${XDG_DATA_HOME:-$HOME/.local/share}/WiiCompiled"
              workspace="$root/workspace"
              bundle=${bundle}

              stage() {
                mkdir -p "$workspace/Launcher"
                if [ ! -f "$workspace/.bundle-version" ] ||
                   [ "$(cat "$bundle/workspace/.bundle-version")" != "$(cat "$workspace/.bundle-version")" ]; then
                  for dir in runtime aurora-main projects; do
                    rm -rf "$workspace/$dir"
                    cp -r "$bundle/workspace/$dir" "$workspace/$dir"
                  done
                  cp "$bundle/workspace/Launcher/local-build.sh" "$workspace/Launcher/local-build.sh"
                  cp "$bundle/workspace/.bundle-version" "$workspace/.bundle-version"
                  chmod -R u+w "$workspace"
                fi

                # Re-pointed on every run, exactly as AppRun does. CMake bakes
                # tool paths into build.ninja and ninja reruns any rule whose
                # command line changed, so the path string has to stay identical
                # across upgrades even as what it resolves to moves.
                [ -L "$workspace/toolchain" ] || rm -rf "$workspace/toolchain"
                [ -L "$workspace/native-prebuilt" ] || rm -rf "$workspace/native-prebuilt"
                ln -sfn "$bundle/usr/toolchain" "$workspace/toolchain"
                ln -sfn "$bundle/native-prebuilt" "$workspace/native-prebuilt"
              }

              # The setup writes its own launcher entries pointing straight at
              # the built binaries. Those resolve libstdc++ and zlib from the
              # sandbox, so a menu click outside it fails -- repoint them at the
              # wrappers, which re-enter the sandbox first.
              fix_desktop_entries() {
                local apps="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"
                if [ -f "$apps/wiicompiled-base.desktop" ]; then
                  sed -i 's|^Exec=.*|Exec=wiicompiled|' "$apps/wiicompiled-base.desktop"
                fi
                if [ -f "$apps/wiicompiled-retro-rewind.desktop" ]; then
                  sed -i 's|^Exec=.*|Exec=wiicompiled-retro-rewind|' "$apps/wiicompiled-retro-rewind.desktop"
                fi
              }

              command=''${1:-}
              shift || true

              case "$command" in
                setup)
                  stage
                  # --fuse-ld resolves ld.lld off PATH, not off --cc's directory.
                  export PATH=${toolchain}/bin:$PATH
                  "$bundle/usr/bin/wiicompiled-setup" \
                    --workspace "$workspace" \
                    --translator-bin "$bundle/usr/bin/translator-cli" \
                    --disc-tool-bin "$bundle/usr/bin/nodtool" \
                    --cc ${toolchain}/bin/clang \
                    --cxx ${toolchain}/bin/clang++ \
                    --fuse-ld lld \
                    --cmake ${toolchain}/bin/cmake \
                    --ninja ${toolchain}/bin/ninja \
                    "$@"
                  fix_desktop_entries
                  ;;
                play)
                  profile=$1
                  shift
                  case "$profile" in
                    Base) binary="$root/Install/Base/WiiCompiled" ;;
                    RetroRewind) binary="$root/Install/RetroRewind/RetroRewind" ;;
                  esac
                  if [ ! -x "$binary" ]; then
                    echo "WiiCompiled is not installed yet. Build it with:" >&2
                    echo "  wiicompiled-setup install --game /path/to/RMCP01.wbfs" >&2
                    exit 1
                  fi
                  exec "$binary" "$@"
                  ;;
                *)
                  echo "usage: wiicompiled-dispatch {setup|play} ..." >&2
                  exit 1
                  ;;
              esac
            '';

            fhsArgs = prev.appimageTools.defaultFhsEnvArgs;

            fhs = prev.buildFHSEnv (
              fhsArgs
              // {
                name = "wiicompiled-fhs";
                runScript = "${dispatch}/bin/wiicompiled-dispatch";

                # The AppImage runner's stock environment ships no ICU, and
                # .NET refuses to start without it -- translator-cli dies in a
                # static constructor before it translates anything. Everything
                # else the translation and the game need (Vulkan, SDL's Wayland
                # and X11 backends, libstdc++, zlib) that environment already
                # has, which is why it is extended rather than replaced.
                targetPkgs = pkgs: (fhsArgs.targetPkgs pkgs) ++ [ pkgs.icu ];
              }
            );
          in
          prev.symlinkJoin {
            name = "wiicompiled-${cfg.wiicompiled.version}";

            paths = [
              (prev.writeShellScriptBin "wiicompiled-setup" ''
                exec ${fhs}/bin/wiicompiled-fhs setup "$@"
              '')
              (prev.writeShellScriptBin "wiicompiled" ''
                exec ${fhs}/bin/wiicompiled-fhs play Base "$@"
              '')
              (prev.writeShellScriptBin "wiicompiled-retro-rewind" ''
                exec ${fhs}/bin/wiicompiled-fhs play RetroRewind "$@"
              '')
            ];

            # No desktop entries are shipped: the game does not exist until the
            # setup has compiled it, and the setup writes its own entries then
            # (repaired above).
            meta = {
              description = "Native PC port of Mario Kart Wii, made with static recompilation";
              homepage = "https://github.com/patchzyy/Wiicompiled";
              license = lib.licenses.gpl3Only;
              mainProgram = "wiicompiled";
              platforms = [ "x86_64-linux" ];
              sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            };
          };
      })
    ];
  };
}
