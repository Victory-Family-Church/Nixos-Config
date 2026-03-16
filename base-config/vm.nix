
{ outputs, inputs, lib, config, pkgs, ... }:{
          networking.networkmanager.enable = true; # NMTUI is dumb easy to use.
           nix.allowedUsers = []; #No access to nix

          time.timeZone = "America/New_York"; # Set Timezone

          nix = {
        # I've been deploying with flakes
            extraOptions = ''
              experimental-features = nix-command flakes 
            '';
          };



          boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
          boot.initrd.kernelModules = [ ];
          boot.kernelModules = [ "kvm-intel" ];
          boot.extraModulePackages = [ ];

          nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
          hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        services.tailscale.enable = true; #vpn access
      users.users = {
        production = {
          isNormalUser = true;
          home = "/home/user";
          description  = "Victory Production";
          uid = 1000; 
          extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
          hashedPassword = "$y$j9T$gfos6aXIGxx6T9SZXIGft/$CuCPpN0BGI.YGe3qsrnZyMSXgDyP6uIVPpACXsXZyY1";
        };
      };
        services.openssh = {
          enable = true;
          ports = [ 22 ];
          settings = {
            PasswordAuthentication = true;
            AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
            UseDns = true;
            X11Forwarding = false;
            PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
          };
        };
      }
