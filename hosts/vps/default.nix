{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  user = config.mainUser.username;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk.nix
    ../default/locale.nix
    ../default/nix-settings.nix
    ../default/secrets.nix
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
    "sd_mod"
    "sr_mod"
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "vps";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # There is no age key file here: sops-nix falls back to the SSH host key
  # once openssh is on.
  sops.age.keyFile = lib.mkForce null;

  # initialPassword is public in this repo, so the account gets no usable
  # password here; sudo goes by SSH key instead.
  users.users.${user} = {
    initialPassword = lib.mkForce null;
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoFsLeOkRzhSxj96/RQ3xVPgAAmoBMDsvfvTyZ7pdEa oxey@nixos"
    ];
    linger = true;
  };
  security.sudo.wheelNeedsPassword = false;

  # Lets nixos-rebuild --target-host push closures built on the laptop.
  nix.settings.trusted-users = [ "@wheel" ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      mainUser = config.mainUser;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = import ./home.nix;
  };

  environment.systemPackages = with pkgs; [
    git
    gcc
    nixfmt
    fd
    nix-index
  ];

  system.stateVersion = "26.11";
}
