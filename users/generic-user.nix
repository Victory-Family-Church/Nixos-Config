
{ outputs, inputs, lib, config, pkgs, ... }:{
    # I don't typically want this, but do in this case.
    users.mutableUsers = true;
    # Define out user
    users.users = {
        user = {
            isNormalUser = true;
            home = "/home/user";
            description  = "user";
            uid = 1000; 
            extraGroups = [ "networkmanager" "dialout" "docker" ]; 
            hashedPassword = "$6$G9mudw188tmjfbTX$Yuutp1clPaRhzjiQrXVi1W6vtTujLLQDQ1dHUq.5.Q1cnHfWGKTjcGOHEVTZcDt5i7fYu8vwulfNpPOmO.bzy1";
        };
    };

    services.openssh.settings = {
        AllowUsers = [ "user" ]; # Allows all users by default. Can be [ "user1" "user2" ]
    };

    nix = {
    extraOptions = ''
        experimental-features = nix-command flakes 
    '';
    allowedUsers = [ "root" ]; # Prevent anyone from accessing nix
    };

}
