{
  config,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "stremio" ''
      exec flatpak run com.stremio.Stremio "$@"
    '')
  ];

  services.flatpak = {
    enable = true;

    uninstallUnused = true;

    # remotes = {
    #   flathub = {
    #     url = "https://flathub.org/repo/flathub.flatpakrepo";
    #   };
    # };

    packages = [
      "com.stremio.Stremio"
    ];
  };

  # `update.onActivation` is disabled because it crashes whenever the rebuild-switch restarts the
  # network, which disables it for updates. Right now it updates + installs new packages, but it
  # won't reinstall packages that are for some reason manually deleted.
  systemd.services.flatpak-managed-install.serviceConfig.ExecStartPre =
    "-${pkgs.flatpak}/bin/flatpak --system update --noninteractive";
}
