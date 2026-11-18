{ pkgs, ... }:
let
  settingsFormat = pkgs.formats.json { };
in
{
  # force: the app has already written its own config.json here.
  xdg.configFile."teams-for-linux/config.json" = {
    force = true;
    source = settingsFormat.generate "teams-for-linux-config.json" {
      platform.spellCheckerLanguages = [
        "en-US"
        "nl"
      ];
    };
  };
}
