{
  description = "Nixos main config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zed-extensions = {
      url = "github:DuskSystems/nix-zed-extensions";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      plasma-manager,
      home-manager,
      zed-extensions,
      nix-flatpak,
      sops-nix,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./hosts/default/configuration.nix
          ./hosts/default/main-user.nix

          {
            mainUser = {
              enable = true;
              username = "oxey";
            };

            nixpkgs.overlays = [
              zed-extensions.overlays.default
            ];

            home-manager.sharedModules = [
              plasma-manager.homeModules.plasma-manager
              zed-extensions.homeManagerModules.default
            ];
          }

          nix-flatpak.nixosModules.nix-flatpak

          sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
        ];
      };

      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust template with flake and .envrc";
        };
      };
    };
}
