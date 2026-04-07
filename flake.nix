{
  description = "nix-config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    darwin-ola.url = "github:Victory-Family-Church/darwin-ola-ftdi";
    npm-packages.url = "github:Victory-Family-Church/Lighting-control-workspace
  };

  outputs = {
    self,
    nixpkgs,
    impermanence,
    disko,
    darwin-ola,
    npm-packages,
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
      lighting = nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs outputs;};
          modules = [
            ({ config, inputs, outputs, ...}: {
              services.ola-ftdi = {
                enable = true;
                web = {
                    enable = true;
                    port = 9090;
                    host = "0.0.0.0"; # expose on network
                };
              };
              nix = {
                # How this isn't a default yet is beyond me.
                  extraOptions = ''
                    experimental-features = nix-command flakes 
                  '';
              };
              services.nodeRedMidiOla = {
                enable = true;
                port = 1880;
              };

# END MODULE Configure
            })
          ];
        };
    }
    nixosConfigurations = {
      micboard = nixpkgs.lib.nixosSystem {
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
              # shut up state version warning
              # Adjust this to your liking.
              disko.devices.disk.system.device = "/dev/sda";
              boot.loader.grub.device = "/dev/sda";

              # WARNING: if you set a too low value the image might be not big enough to contain the nixos installation
              #disko.devices.disk.system.imageSize = "10G";
            })
            ./disk-config/mac-mini.nix
            ./base-config/mac-mini.nix # Base system config. Meant to be extended with below lines.
            ./service-config/docker/containerd.nix # Configure docker daemon.
            ./service-config/docker/micboard.nix # Run Micboard with docker via systemd.
            ./service-config/UI/micboard-openbox-kiosk.nix # Run a basic Cage session with epiphany. Allows micboard to just be the mac and a display.
        ];
      };
    devnix = nixpkgs.lib.nixosSystem {
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
              nixpkgs.system = "aarch64-linux";
              disko.devices.disk.system.device = "/dev/vda";
            })
            ./disk-config/vm.nix
            ./base-config/vm.nix # Base system config. Meant to be extended with below lines.

        ];
      };
    };
      bootstrap = nixpkgs.lib.nixosSystem {
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
              # shut up state version warning
              # Adjust this to your liking.
              disko.devices.disk.system.device = "/dev/sda";
              boot.loader.grub.device = "/dev/sda";
              # WARNING: if you set a too low value the image might be not big enough to contain the nixos installation
              #disko.devices.disk.system.imageSize = "10G";
            })
            ./disk-config/mac-mini.nix
            ./service-config/UI/gnome.nix
            ./base-config/mac-mini.nix # Base system config. Meant to be extended with below lines.
        ];
      };
    };
  }

