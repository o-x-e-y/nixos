{ config, pkgs, inputs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "stremio" ''
      exec flatpak run com.stremio.Stremio "$@"
    '')
  ];

  services.flatpak = {
    enable = true;

    # remotes = {
    #   flathub = {
    #     url = "https://flathub.org/repo/flathub.flatpakrepo";
    #   };
    # };

    packages = [
      "com.stremio.Stremio"
    ];
  };
}
