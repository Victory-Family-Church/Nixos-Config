{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.impermanence.nixosModules.impermanence
      inputs.disko.nixosModules.disko
    ];
  disko.devices = {
    disk = {
       system = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            esp = {
                priority = 1;
                name = "esp";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
            };
            data = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                subvolumes = {
                  "/system-data" = { # Store docker and system states here
                      mountOptions = [ "compress=zstd" "noexec" ];
                      mountpoint = "/system-data";
                  };
                  "/nix" = { # Nix store, needed for boot
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "spotify-offline-cache" = { # Nix store, needed for boot
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/home/spotify/.cache/spotify";
                  };
                  "spotify-data" = { # Nix store, needed for boot
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/home/spotify/.cache/spotify";
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev."/" = { # Root-as-tmpfs
      fsType = "tmpfs";
      mountOptions = [
        "size=512M"
        "defaults"
        "mode=755"
      ];
    };
    nodev."/home/spotify" = { # Home-as-tmpfs
      fsType = "tmpfs";
      mountOptions = [
        "size=1G"
        "user"
        "defaults"
        "mode=1777"
        "noexec"
      ];
    };
  };
  # Ensure our filesystems exist before booting stage-2?
  fileSystems."/system-data".neededForBoot = true;
  # These are directories we need to keep
  environment.persistence."/system-data/systemState" = {
    enable = true; 
    hideMounts = true;
    directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/tailscale/"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
    ];
  };
}
