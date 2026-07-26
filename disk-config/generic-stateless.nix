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
                  "/docker-commpose" = { # Optional, incase we want to deploy compose projects out-of-band.
                      mountOptions = [ "compress=zstd" "noexec" "ro" ];
                      mountpoint = "/docker-compose";
                  };
                  "/system-data" = { # Store docker and system states here
                      mountOptions = [ "compress=zstd" "noexec" ];
                      mountpoint = "/system-data";
                  };
                  "/nix" = { # Nix store, needed for boot
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "/docker" = { # Docker daemon data dir
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/docker-data";
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
    nodev."/home/user" = { # Home-as-tmpfs
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
  fileSystems."/docker-data".neededForBoot = true;
  fileSystems."/docker-compose".neededForBoot = true;
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
    files = [
      { file = "/etc/machine-id"; parentDirectory = { mode = "u=rwx,g=rwx,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
    ];
  };
  
# I really enjoy systemd-boot, but this ensures everything looks/feels the same between legacy and uefi systems.
  boot.loader = {
    efi = {
        canTouchEfiVariables = false;
    };
    grub = {
        enable = true;
        efiInstallAsRemovable = true;
        efiSupport = true;
        version = 3;
    };
  };
}
