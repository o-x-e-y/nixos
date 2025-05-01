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
  };

  outputs = { self, nixpkgs, plasma-manager, home-manager, zed-extensions, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      
      modules = [
        ./modules
        ./hosts/default/configuration.nix
        {
          nixpkgs.overlays = [
            zed-extensions.overlays.default
          ];
        }
        home-manager.nixosModules.home-manager
        {
          home-manager.sharedModules = [
            plasma-manager.homeManagerModules.plasma-manager
            zed-extensions.homeManagerModules.default
          ];
        }
      ];
    };
  };
}
