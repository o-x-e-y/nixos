{
  pkgs,
  lib,
  mainUser,
  ...
}:
let
  mkLocalTypstPackages =
    names:
    builtins.listToAttrs (
      map (name: {
        name = ".local/share/typst/packages/local/${name}/0.1.0";
        value = {
          source = ../../dotfiles/typst/${name}/0.1.0;
          recursive = true;
        };
      }) names
    );
in
{
  imports = [
    ./../../home/programs
  ];

  apps = {
    alacritty.enable = false;
    foot.enable = false;
    ghostty.enable = false;
    libreoffice.extraPackages = with pkgs; [
      hunspellDicts.en_GB-ise
      hunspellDicts.nl_NL
    ];
  };

  home.username = "${mainUser.username}";
  home.homeDirectory = "/home/${mainUser.username}";

  # Read the Home Manager release notes before changing.
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    discord
    kdePackages.kate
    spotify
    teams-for-linux
    typst
    typstyle
    plantuml
    tinymist
    gimp3
    ungoogled-chromium
    package-version-server
    mesen
    zig
    clang-tools
    signal-desktop
    mold
    sqlite
    glow
    bat
    git-fame
    git-filter-repo
    speedtest-cli
    qbittorrent
    haruna
    obs-studio
    claude-monitor
    fend
    oxeylyzer
    wheelwizard
    google-chrome

    # (pkgs.writeShellScriptBin "cc" "${pkgs.gcc}/bin/gcc")
  ];

  home.file = {
    ".face.icon" = {
      source = ./../../public/oxey-pfp.png;
    };

    ".config/nixpkgs" = {
      source = ./../../dotfiles/nixpkgs;
      recursive = true;
    };

    ".cargo/config.toml".text = ''
      [target.x86_64-unknown-linux-gnu]
      rustflags = ["-C", "link-arg=-fuse-ld=mold"]
    '';
  }
  // (mkLocalTypstPackages [
    "template"
    "competence-template"
    "requirements"
    "training-plan"
    "skeleton"
  ]);

  home.activation.applyTetrisGymPatch = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rom="$HOME/Games/tetris-usa.nes"
    out="$HOME/Games/tetris-gym.nes"
    if [ -f "$rom" ] && [ ! -f "$out" ]; then
      $DRY_RUN_CMD ${pkgs.flips}/bin/flips --apply ${../../public/TetrisGYM-6.0.0.bps} "$rom" "$out"
    fi
  '';

  home.sessionVariables = {
    BROWSER = "firefox";
    TERMINAL = "konsole";
    EDITOR = "zeditor";
    # LD_LIBRARY_PATH = "${pkgs.gcc}/lib";
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;
}
