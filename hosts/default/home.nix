{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./../../home/profiles/cli.nix
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

  # Read the Home Manager release notes before changing.
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    discord
    kdePackages.kate
    spotify
    teams-for-linux
    gimp3
    ungoogled-chromium
    mesen
    signal-desktop
    qbittorrent
    haruna
    obs-studio
    oxeylyzer
    wheelwizard
    google-chrome
    git-fame

    # (pkgs.writeShellScriptBin "cc" "${pkgs.gcc}/bin/gcc")
  ];

  home.file.".face.icon".source = ./../../public/oxey-pfp.png;

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

  programs.bash.shellAliases = {
    "zed" = "${pkgs.zed-editor}/bin/zeditor";
    "code" = "${pkgs.vscodium}/bin/codium";
    "edit-sops" = "EDITOR=\"codium --wait\" sops ~/nixos/secrets/secrets.yaml";
  };

  fonts.fontconfig.enable = true;
}
