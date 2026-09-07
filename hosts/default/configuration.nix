{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./desktop.nix
    ./flatpak.nix
    ./fonts.nix
    ./hardware.nix
    ./locale.nix
    ./nix-settings.nix
    ./secrets.nix
    ./../../modules
  ];

  modules = {
    kanata.enable = true;
    opentabletdriver.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      mainUser = config.mainUser;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      "${config.mainUser.username}" = import ./home.nix;
    };
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    git
    nixd
    nil
    gcc
    nixfmt
    fd
    nix-index
  ];

  # systemd already caps the journal at 4G by default; this bounds it by age too.
  services.journald.extraConfig = "MaxRetentionSec=6month";

  # Leave at the release version of the first install; read the docs before changing.
  system.stateVersion = "24.11";
}
