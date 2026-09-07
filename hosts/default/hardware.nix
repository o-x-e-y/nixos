{
  pkgs,
  ...
}:
{
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];
  hardware.printers.ensurePrinters = [
    {
      name = "Canon_MG2500";
      deviceUri = "usb://Canon/MG2500%20series?serial=934970&interface=1";
      model = "gutenprint.5.3://bjc-MG2500-series/expert";
      description = "Canon PIXMA MG2500";
    }
  ];

  hardware.bluetooth.enable = true;
  hardware.wooting.enable = true;

  virtualisation.docker.enable = true;
}
