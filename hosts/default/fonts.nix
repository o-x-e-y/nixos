{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    # Fonts not available through google
    nerd-fonts.jetbrains-mono

    # Note: missing names fail silently without crashing the build
    (google-fonts.override {
      fonts = [
        "Yrsa"
        "DM Sans"
        "Cascadia Code"
        "Inter"
        "IBM Plex Sans"
        "Source Serif 4"
        "Libre Baskerville"
        "Roboto"
        "Courier Prime"
      ];
    })
  ];
}
