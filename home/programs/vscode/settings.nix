{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.vscode;
in
{
  config = lib.mkIf cfg.enable {
    programs.vscode = {
      profiles.default = {
        userSettings = {
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "editor.fontSize" = 16;
          "debug.console.fontSize" = 16;
          "terminal.integrated.fontSize" = 16;
          "workbench.colorTheme" = "Vim Dark Hard";
          "workbench.iconTheme" = "gruvbox-material-icon-theme";
          "window.zoomLevel" = 0.2;
          "window.zoomPerWindow" = false;
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "files.encoding" = "utf8";
          "files.insertFinalNewline" = true;
          "files.trimFinalNewlines" = true;
          "files.trimTrailingWhitespace" = true;
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
          "explorer.confirmPasteNative" = false;
          "[nix]"."editor.tabSize" = 2;
        };
      };
    };
  };
}
