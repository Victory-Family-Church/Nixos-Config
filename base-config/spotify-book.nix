
{ outputs, inputs, lib, config, pkgs, ... }:{
    networking.networkmanager.enable = true; # NMTUI is dumb easy to use.
    # All of these devices exist in my timezone
    time.timeZone = "America/New_York";

    # Define out user
    users.users = {
        spotify = {
            isNormalUser = true;
            home = "/home/spotify";
            description  = "Spotify";
            uid = 1000; 
            extraGroups = [ "networkmanager" "storage" ]; 
            hashedPassword = "$y$j9T$gfos6aXIGxx6T9SZXIGft/$CuCPpN0BGI.YGe3qsrnZyMSXgDyP6uIVPpACXsXZyY1";
        };
    };


    nix = {
    extraOptions = ''
        experimental-features = nix-command flakes 
    '';
    allowedUsers = []; # Prevent anyone from accessing nix
    };

}
