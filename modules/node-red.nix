{ config, lib, pkgs, ... }:

let
  cfg = config.services.nodeRed;
in
{
  options.services.nodeRed = {
    enable = lib.mkEnableOption "Node-RED service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 1880;
    };

    userDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/node-red";
    };
  };

  config = lib.mkIf cfg.enable {

    # macOS requires explicit UID >= 501
    users.users.nodered = {
      uid = 510;
      gid = 20;              # staff
      home = cfg.userDir;
      shell = pkgs.bash;
      createHome = true;
      isHidden = true;
    };

    launchd.daemons.node-red = {
      script = ''
        set -e

        export NODE_RED_HOME=${cfg.userDir}

        mkdir -p "$NODE_RED_HOME"
        mkdir -p "$NODE_RED_HOME/node_modules"
        chown -R nodered:staff "$NODE_RED_HOME"

        exec ${pkgs.nodePackages.node-red}/bin/node-red \
          --userDir "$NODE_RED_HOME" \
          --port ${toString cfg.port}
      '';

      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = true;
        UserName = "nodered";
        StandardOutPath = "/var/log/node-red.log";
        StandardErrorPath = "/var/log/node-red.err";
      };
    };
  };
}
``