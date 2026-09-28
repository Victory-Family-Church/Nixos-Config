# Prometheus server, reachable ONLY over Tailscale (for the remote Grafana instance).
#
# First boot:  sudo tailscale up --hostname=prometheus
#   (state is persisted, so this is one-time; disable key expiry for this node in the Tailscale admin console)
# Grafana data source URL:  http://prometheus:9090  (MagicDNS)  or  http://<tailscale-ip>:9090
{ config, lib, pkgs, ... }:
let
  promPort = 9090;
  nodeExporterPort = 9100;
in {
  # --- Tailscale ---------------------------------------------------------
  services.tailscale = {
    enable = true;
    openFirewall = true; # UDP 41641 for direct (non-DERP) connections
    # Optional unattended join: drop a key on the persisted volume and uncomment.
    # authKeyFile = "/system-data/secrets/tailscale-authkey";
  };

  # --- Firewall: Prometheus only on the tailnet interface -----------------
  networking.firewall = {
    enable = true;
    interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ promPort ];
  };

  # --- Prometheus --------------------------------------------------------
  services.prometheus = {
    enable = true;
    port = promPort;
    listenAddress = "0.0.0.0"; # firewall limits exposure to tailscale0
    retentionTime = "90d";
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    exporters.node = {
      enable = true;
      port = nodeExporterPort;
      listenAddress = "127.0.0.1"; # local scrape only
      enabledCollectors = [ "systemd" "processes" ];
    };

    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [{ targets = [ "127.0.0.1:${toString promPort}" ]; }];
      }
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString nodeExporterPort}" ];
          labels.instance = config.networking.hostName;
        }];
      }
      # Add more hosts later, e.g. over Tailscale MagicDNS:
      # { job_name = "fleet"; static_configs = [{ targets = [ "resi-aux:9100" "micboard:9100" ]; }]; }
    ];
  };

  # --- Persistence (root is tmpfs via partial-stateless.nix) -------------
  environment.persistence."/system-data/systemState".directories = [
    { directory = "/var/lib/tailscale"; mode = "0700"; }
    { directory = "/var/lib/${config.services.prometheus.stateDir}"; user = "prometheus"; group = "prometheus"; mode = "0700"; }
  ];
}
