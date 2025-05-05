{ config, pkgs, ... }:
{
  home-manager.users.${config.main-user.username} = {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
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
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vim-theme";
            publisher = "harryhopkinson";
            version = "1.1.8";
            sha256 = "sha256-W/OaCEhMbBkmtqIezTs0DJbZQyUVMshY3XiPPHcgf7Y=";
          }
          {
            name = "gruvbox-material-icon-theme";
            publisher = "jonathanharty";
            version = "1.1.5";
            sha256 = "sha256-86UWUuWKT6adx4hw4OJw3cSZxWZKLH4uLTO+Ssg75gY=";
          }
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
  };
}
