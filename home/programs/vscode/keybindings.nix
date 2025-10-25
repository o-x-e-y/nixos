{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.vscode;
in
{
  config = lib.mkIf (cfg.enable && cfg.useKeybindings) {
    programs.vscode = {
      profiles.default = {
        keybindings = [
          {
            key = "ctrl+`";
            command = "-workbench.action.terminal.toggleTerminal";
            when = "terminal.active";
          }
          {
            key = "ctrl+`";
            command = "workbench.action.togglePanel";
          }
          {
            key = "ctrl+j";
            command = "-workbench.action.togglePanel";
          }
          {
            key = "shift+escape";
            command = "workbench.action.toggleMaximizedPanel";
          }
        ];
      };
    };
  };
}
