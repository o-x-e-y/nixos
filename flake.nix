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

    oxeylyzer = {
      url = "github:o-x-e-y/oxeylyzer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pathe-cli = {
      url = "github:o-x-e-y/pathe-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deepseek-harness = {
      url = "github:moraxyc/deepseek-harness.nix";
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
      oxeylyzer,
      pathe-cli,
      deepseek-harness,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./hosts/default/configuration.nix
          ./hosts/default/main-user.nix
          ./hosts/default/claude-code-override.nix
          ./hosts/default/wheelwizard-override.nix

          {
            mainUser = {
              enable = true;
              username = "oxey";
            };

            claudeCodeOverride = {
              enable = true;
              version = "2.1.258";
              hash = "sha256-cE8TNKxl0+ieHGwddmMpOteGphZq/bcbUHUzffYw+XY=";
            };

            wheelwizardOverride = {
              enable = true;
              version = "2.5.3";
              hash = "sha256-yh0kRPfs/g47Hrn+T3MHR2/Vyf7aPTWsszUQNBfw0W4=";

              dolphin = {
                version = "2606a";
                hash = "sha256-TAIxBEGbbYvoOi+dukr2Hij0J/NL9Iy6pcgf2bhEgI8=";
              };

              wiicompiled = {
                version = "0.2.27";
                hash = "sha256-QYIxF9KkXZZcRGrPLnze22hG7NeJVwyBtnRTMUSBGvs=";
              };
            };

            nixpkgs.overlays = [
              zed-extensions.overlays.default
              oxeylyzer.overlays.default
              pathe-cli.overlays.default
              deepseek-harness.overlays.default
            ];

            home-manager.sharedModules = [
              plasma-manager.homeModules.plasma-manager
              zed-extensions.homeManagerModules.default
              deepseek-harness.homeModules.default
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
