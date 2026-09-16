
{ inputs, outputs, lib, pkgs, ... }:{
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the LightDM display manager.
    services.xserver.displayManager.lightDM.enable = true;

    # Enable the MATE Desktop Environment.
    services.xserver.desktopManager.mate.enable = true;
}