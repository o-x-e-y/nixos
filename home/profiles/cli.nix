{
  pkgs,
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
    ../programs/bash
    ../programs/bat
    ../programs/boxd
    ../programs/btop
    ../programs/canvas
    ../programs/claude-code
    ../programs/direnv
    ../programs/dsh
    ../programs/fastfetch
    ../programs/git
    ../programs/ledger
    ../programs/ortec
    ../programs/pathe
    ../programs/route
    ../programs/ssh
  ];

  home.username = "${mainUser.username}";
  home.homeDirectory = "/home/${mainUser.username}";

  home.packages = with pkgs; [
    typst
    typstyle
    plantuml
    mold
    sqlite
    glow
    bat
    speedtest-cli
    fend
  ];

  home.file = {
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
