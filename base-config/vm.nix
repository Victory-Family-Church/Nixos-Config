
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
  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;
  boot = {
    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = with pkgs; [
        nixos-bgrt-plymouth
      ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "bgrt_disable=0" 
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };
}
