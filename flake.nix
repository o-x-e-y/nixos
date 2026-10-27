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

    ortec-mcp = {
      url = "github:o-x-e-y/ortec-mcp";
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
      ortec-mcp,
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
              enable = false;
              version = "2.1.311";
              hash = "sha256-0MALgHYfMDDzTPCBImb2xvghD/mvckL3xsdsVgBJnK8=";
            };

            wheelwizardOverride = {
              enable = true;
              version = "2.6.2";
              hash = "sha256-FAPl0ZcFYgk4VR6EUROQlc6ZcJNCH+K4xYPzvhI3k2E=";

              dolphin = {
                version = "2609a";
                hash = "sha256-0yQVW7Q3EKqfGihVA9I8Ucs0Hn/QVGVXuZ8ePbCZ5TQ=";
              };

              wiicompiled = {
                version = "0.2.34";
                hash = "sha256-fOrUVcom55bQ8xK/TGvYA3w9a2Ob/uf48GMuI52Hcmg=";
              };
            };

            nixpkgs.overlays = [
              zed-extensions.overlays.default
              oxeylyzer.overlays.default
              pathe-cli.overlays.default
              ortec-mcp.overlays.default
              deepseek-harness.overlays.default
            ];

            home-manager.sharedModules = [
              plasma-manager.homeModules.plasma-manager
              zed-extensions.homeManagerModules.default
              deepseek-harness.homeModules.default
              pathe-cli.homeManagerModules.default
              ortec-mcp.homeManagerModules.default
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
        bun = {
          path = ./templates/bun;
          description = "Bun template with flake and .envrc";
        };
      };
    };
}
