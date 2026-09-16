{ inputs, outputs, lib, pkgs, ... }:{
  virtualisation.docker.enable = true; # Enable oci containers.
  virtualisation.oci-containers.backend = "docker"; # Make sure we're actually using docker, and not podman.
  virtualisation.docker.liveRestore = false; # This breaks swarms
#  virtualisation.docker.daemon.settings = { # Set Docker-Daemon path to non-tmpfs location, /docker-data is a btrfs vol
#    data-root = "/docker-data";
#  };
}
