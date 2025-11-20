{ pkgs, mainUser, ... }:
{
  imports = [
    ./../../home/programs
  ];

  apps = {
    alacritty.enable = false;
    foot.enable = false;
    libreoffice.extraPackages = with pkgs; [
      hunspellDicts.en_GB-ise
      hunspellDicts.nl_NL
    ];
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "${mainUser.username}";
  home.homeDirectory = "/home/${mainUser.username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    discord
    spotify
    teams-for-linux
    typst
    typstyle
    tinymist
    gimp3
    ungoogled-chromium
    package-version-server
    mesen
    zig
    clang-tools
    signal-desktop
    mold
    postman
    sqlite
    glow
    bat
    git-fame
    git-filter-repo

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    # (pkgs.writeShellScriptBin "cc" "${pkgs.gcc}/bin/gcc")
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/oxey/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    BROWSER = "firefox";
    TERMINAL = "konsole";
    EDITOR = "zeditor";
    # LD_LIBRARY_PATH = "${pkgs.gcc}/lib";
  };

  home.file.".face.icon".source = ./../../public/oxey-pfp.png;

  home.file.".config/nixpkgs" = {
    source = ./../../dotfiles/nixpkgs;
    recursive = true;
  };

  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    rustflags = ["-C", "link-arg=-fuse-ld=mold"]
  '';

  fonts.fontconfig.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
