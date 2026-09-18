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

    update.onActivation = true;
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

  # update.onActivation only appends --or-update to the install of each declared
  # app, and `flatpak update REF` updates that ref alone -- the runtimes under it
  # (org.gnome.Platform, org.freedesktop.Platform.GL.default, codecs-extra) are
  # dependencies, not related refs, so they would never move. A bare `flatpak
  # update` covers everything, and running it first means the uninstallUnused
  # sweep at the end of the module's own script prunes whatever it superseded.
  # Prefixed with `-` so an offline rebuild leaves the unit green and still
  # installs anything newly declared.
  systemd.services.flatpak-managed-install.serviceConfig.ExecStartPre =
    "-${pkgs.flatpak}/bin/flatpak --system update --noninteractive";
}
