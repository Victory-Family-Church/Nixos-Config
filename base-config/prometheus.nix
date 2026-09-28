{ outputs, inputs, lib, config, pkgs, ... }:{
    networking.hostName = "prometheus";
    networking.networkmanager.enable = true; # NMTUI is dumb easy to use.
    time.timeZone = "America/New_York"; # Set Timezone

    services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
        PasswordAuthentication = true;
        UseDns = true;
        X11Forwarding = false;
        PermitRootLogin = "no"; # generic-user.nix restricts AllowUsers to "user" anyway
        };
    };

    nix = {
    extraOptions = ''
        experimental-features = nix-command flakes
    '';
    };

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "uas" "usbhid" "sd_mod" "btrfs" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
