{
  description = "nix-config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    darwin-ola.url = "github:Victory-Family-Church/darwin-ola-ftdi";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    impermanence,
    disko,
    darwin-ola,
    darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    darwinConfigurations = {
      lighting = darwin.lib.darwinSystem {
        system = "aarch64-darwin";

        modules = [
          ({ pkgs, ... }: {
            system.stateVersion = 6;
            nixpkgs.overlays = [  
              inputs.darwin-ola.overlays.default
            ];
            environment.systemPackages = with pkgs; [
              olaftdi
              nodejs_25
            ];
            nixpkgs.config.problems.handlers = {
              ola.broken = "warn";   # or "ignore"
            };
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          })
        ];
      };
    };
    nixosConfigurations = {
      micboard = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            disko.nixosModules.disko
            ({ config, ... }: {
              nixpkgs.system = "x86_64-linux";
              system.stateVersion = "24.11";
              disko.devices.disk.system.device = "/dev/sda";
              boot.loader.grub.device = "/dev/sda";
            })
            ./disk-config/mac-mini.nix
            ./base-config/mac-mini.nix # Base system config. Meant to be extended with below lines.
            ./service-config/docker/containerd.nix # Configure docker daemon.
            ./service-config/docker/micboard.nix # Run Micboard with docker via systemd.
            ./service-config/UI/micboard-openbox-kiosk.nix # Run a basic Cage session with epiphany. Allows micboard to just be the mac and a display.
        ];
      };
      resi-aux = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            disko.nixosModules.disko
            ({ config, ... }: {
              nixpkgs.system = "x86_64-linux";
              system.stateVersion = "26.05";
              disko.devices.disk.system.device = "/dev/sdb";
              boot.loader.grub.device = "/dev/sdb";
            })
            ./users/generic-user.nix
            ./disk-config/partial-stateless.nix
            ./base-config/resi-aux.nix # Base system config. Meant to be extended with below lines.
            ./service-config/docker/containerd.nix # Configure docker daemon.
            ./service-config/UI/mate.nix 
        ];
      };
# Lights for Stu min
      lights = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ({ config, ... }: {
              # shut up state version warning
              nixpkgs.system = "x86_64-linux";
              system.stateVersion = "24.11";
              # Adjust this to your liking.
              # WARNING: if you set a too low value the image might be not big enough to contain the nixos installation
            })
            disko.nixosModules.disko
            ({ config, ... }: {
              disko.devices.disk.system.device = "/dev/vda";
              nixpkgs.system = "aarch64-linux";
              boot.loader.grub.device = "/dev/vda";
            })
            ./disk-config/generic-stateless.nix
            ./base-config/lights.nix # Base system config. Meant to be extended with below lines.
        ];
      };

      devnix = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs;};
            modules = [
              disko.nixosModules.disko
              ({ config, ... }: {
                nixpkgs.system = "x86_64-linux";
                system.stateVersion = "24.11";
                disko.devices.disk.system.device = "/dev/vda";
              })
              ./disk-config/vm.nix
              ./base-config/vm.nix # Base system config. Meant to be extended with below lines.
          ];
        };
    };
  };
}

