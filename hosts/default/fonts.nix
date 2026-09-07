{
  pkgs,
  ...
}:
let
  font-to-static = pkgs.writeShellApplication {
    name = "font-to-static";
    runtimeInputs = [ pkgs.python3Packages.fonttools ];
    text = ''
      src="$1"
      name="$(basename "$src" '.ttf')"
      for wght in 100 200 300 400 500 600 700 800 900; do
        fonttools varLib.mutator -o "$name-$wght.ttf" "$src" wght="$wght"
      done
    '';
  };

  fonts-static =
    (pkgs.google-fonts.override {
      fonts = [
        "Yrsa"
        "DM Sans"
        "Cascadia Code"
        "Inter"
        "IBM Plex Sans"
        "Source Serif 4"
      ];
    }).overrideAttrs
      (
        final: prev: {
          nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ font-to-static ];

          preFixup = ''
            find "$out" -name '*.ttf' -execdir font-to-static '{}' ';'
          '';
        }
      );
in
{
  fonts.packages = with pkgs; [
    noto-fonts
    nerd-fonts.jetbrains-mono
    texlivePackages.librebaskerville
    texlivePackages.inter
    courier-prime
    roboto
    fonts-static
  ];
}
