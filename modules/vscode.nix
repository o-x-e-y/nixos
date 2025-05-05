{ config, pkgs, ... }:
{
  home-manager.users.${config.main-user.username} = {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      extensions = with pkgs.vscode-extensions; [
        harryhopkinson.vim-theme
        jonathanharty.gruvbox-material-icon-theme
        mfederczuk.w3c-ebnf
        ritwickdey.liveserver
        tamasfe.even-better-toml
        mechatroner.rainbow-csv
        davidanson.vscode-markdownlint
        kamikillerto.vscode-colorize
        myriad-dreamin.tinymist
        # bradlc.vscode-tailwindcss
        # austenc.tailwind-docs
        # bourhaouta.tailwindshades
        # huber-baste.msgpack
        # github.vscode-github-actions
        # ms-vscode.makefile-tools
        # charliermarsh.ruff
        # ms-python.python
        # qwtel.sqlite-viewer
        # rust-lang.rust-analyzer
      ];
      userSettings = {
        "git.autofetch" = true;
        "files.autoSave" = "afterDelay";
        "editor.fontSize" = 14;
        "debug.console.fontSize" = 14;
        "terminal.integrated.fontSize" = 14;
        "window.zoomLevel" = 1;
        "[nix]"."editor.tabSize" = 2;
      };
    };
  };
}