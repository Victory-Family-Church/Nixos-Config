
{ outputs, inputs, lib, config, pkgs, ... }:{
    networking.networkmanager.enable = true; # NMTUI is dumb easy to use.
    nix.allowedUsers = [ root ]; #No access to nix
    time.timeZone = "America/New_York"; # Set Timezone

    nix = {
    extraOptions = ''
        experimental-features = nix-command flakes 
    '';
    };


    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.tailscale.enable = true; #vpn access

    # X server + MATE desktop
    services.xserver.enable = true;
    services.xserver.desktopManager.mate.enable = true;
    services.displayManager.defaultSession = "mate";

    # Quick headless VNC via x11vnc (listens on :5900, spawns an
    # Xvfb-backed X server per authenticated user on connect)
    imports = [ <nixpkgs/nixos/modules/services/x11/terminal-server.nix> ];

    networking.firewall.allowedTCPPorts = [ 5900 ];

    environment.defaultPackages = lib.mkForce (with pkgs; [
        mapmap
        qlcplus
    ]);

    users.users = {
        lights = {
            isNormalUser = true;
            home = "/home/user";
            description  = "user for ssh access";
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
        AllowUsers = [ "root" ]; # Allows all users by default. Can be [ "user1" "user2" ]
        UseDns = true;
        X11Forwarding = false;
        PermitRootLogin = "yes"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
        };
    };
}
