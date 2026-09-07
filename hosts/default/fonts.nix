{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    noto-fonts
    nerd-fonts.jetbrains-mono
    texlivePackages.librebaskerville
    texlivePackages.inter
    courier-prime
    roboto

    # These six ship from Google as variable fonts only. Typst reads the
    # wght/wdth/opsz axes directly since 0.15, so they no longer need to be
    # instantiated into static weights first.
    (google-fonts.override {
      fonts = [
        "Yrsa"
        "DM Sans"
        "Cascadia Code"
        "Inter"
        "IBM Plex Sans"
        "Source Serif 4"
      ];
    })
  ];
}
