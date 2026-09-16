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
                    "/user-data" = {
                        mountOptions = [ "compress=zstd" "noexec" ]; # we will not run binaries from the FS
                        mountpoint = "/home/user";
                    };
                    "/system-data" = { # Store docker and system states here
                        mountOptions = [ "compress=zstd" "noexec" ];
                        mountpoint = "/system-data";
                    };
                    "/nix-store" = { # Nix store, needed for boot
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/nix";
                    };
                    "/docker-data" = { # Docker daemon data dir
                        mountOptions = [ "compress=zstd" "noatime" ];
                        mountpoint = "/docker";
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
  };

  # Ensure our filesystems exist before booting stage-2?
  fileSystems."/docker".neededForBoot = true;  # matches the /docker-data subvolume's actual mountpoint above
  fileSystems."/home/user".neededForBoot = true;
  fileSystems."/system-data".neededForBoot = true;

  # These are directories we need to keep
  environment.persistence."/system-data/systemState" = {
    enable = true; 
    hideMounts = true;
    directories = [
        "/var/log"
        "/var/lib/nixos"
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
}
