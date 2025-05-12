{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.zed-editor;
in
{
  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      userKeymaps = [
        {
          context = "Workspace";
          bindings = {
            "ctrl-`" = "workspace::ToggleBottomDock";
            "ctrl-r" = "projects::OpenRecent";
            # "ctrl-:" = "editor::ToggleInlayHints";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl+t" = "workspace::NewTerminal";
          };
        }
        {
          context = "Editor";
          bindings = {
            # "j k": ["workspace::SendKeystrokes", "escape"]
          };
        }
      ];
    };
  };
}
