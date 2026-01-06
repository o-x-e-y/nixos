{ config, pkgs, inputs, ... }:
{
  # Enable system-wide Flatpak service
  services.flatpak.enable = true;

  nix-flatpak = {
    enable = true;

    remotes = {
      flathub = {
        url = "https://flathub.org/repo/flathub.flatpakrepo";
      };
    };

    packages = [
      "com.stremio.Stremio"
    ];
  };
}
