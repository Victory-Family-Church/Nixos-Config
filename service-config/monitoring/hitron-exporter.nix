# Hitron CODA-45 cable modem exporter (Armstrong), scraped by the local Prometheus.
#
# The CODA-45 status UI (http://192.168.100.1) has no login, so no secrets are needed;
# the exporter's login attempt fails harmlessly and it reads the status APIs directly.
# This box must reach 192.168.100.1 via its default route (not a local bridge on that subnet).
# Test: curl -s localhost:9780/scrape | grep -E 'hitron_up|downstream'
{ config, lib, pkgs, ... }:
let
  port = 9780;
  configFile = pkgs.writeText "hitron_coda.yml" (builtins.toJSON {
    host = "192.168.100.1";
    username = "cusadmin"; # unused on CODA-45 (no login); kept for routers like the CODA-4680
    password = "password";
    modem_only = true; # bridge-only: skip Router/WiFi APIs
  });
  hitron-coda-exporter = pkgs.callPackage ../../pkgs/hitron-coda-exporter { };
in {
  systemd.services.hitron-coda-exporter = {
    description = "Prometheus exporter for Hitron CODA cable modem";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe hitron-coda-exporter)
        "--config.file=${configFile}"
        "--web.listen-address=127.0.0.1:${toString port}"
      ];
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = 10;

      # Hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      CapabilityBoundingSet = "";
    };
  };

  services.prometheus.scrapeConfigs = [
    {
      # Modem metrics (DOCSIS channels, SNR, power, errors). Each scrape logs in to the modem.
      job_name = "hitron_coda";
      metrics_path = "/scrape";
      scrape_interval = "60s";
      scrape_timeout = "30s";
      static_configs = [{ targets = [ "127.0.0.1:${toString port}" ]; labels.instance = "coda-45"; }];
    }
    {
      # Exporter's own health (request/client error counters).
      job_name = "hitron_coda_exporter";
      static_configs = [{ targets = [ "127.0.0.1:${toString port}" ]; }];
    }
  ];
}
