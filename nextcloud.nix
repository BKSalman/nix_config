{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with builtins; let
  cfg = config.nextcloud;

  # Cleanup override info
  settings =
    pkgs.lib.mapAttrsRecursiveCond
    (s: ! s ? "_type")
    (_: value:
      if value ? "content"
      then value.content
      else value)
    cfg.settings;
in {
  options.nextcloud = {
    enable = mkEnableOption "Enable nextcloud";

    apps = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "
        Nextcloud apps to enable
      ";
    };

    adminEmail = mkOption {
      type = types.str;
      default = "admin@${config.networking.domain}";
      description = "
        The email address of the default admin user
      ";
    };

    settings = mkOption {
      type = types.attrsOf types.attrs;
      default = {};
      description = "
        Nextcloud settings to be imported using `occ config:import`

        https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/occ_command.html#config-commands
      ";
    };
  };

  config = mkIf cfg.enable {
    services.mysql = {
      enable = true;
      package = pkgs.mysql;
      ensureDatabases = ["nextcloud"];
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions = {
            "nextcloud.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "localhost" = {
          locations = {
            default = true;
            "/" = {
              proxyPass = "http://localhost";
            };
            "/office" = {
              proxyPass = "http://localhost:9980";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
                proxy_set_header Host $host;
                proxy_read_timeout 36000s;
              '';
            };
          };
        };
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud25;
    logLevel = 0;
    hostName = "localhost";
    extraApps = cfg.apps;
    caching = {
      apcu = true;
    };
    config = {
      dbtype = "mysql";
      adminuser = "admin";
      extraTrustedDomains = ["100.64.0.1"];
      adminpassFile = "${pkgs.writeText "adminpass" "test123"}";
    };
  };

  # This is to do the initial nextcloud setup only when Mysql and
  # Redis are ready. We need to add this because mysql is on the same
  # host.
  systemd.services.nextcloud-setup = {
    serviceConfig.RemainAfterExit = true;
    partOf = ["phpfpm-nextcloud.service"];
    after = ["nextcloud-admin-key.service" "mysql.service"];
    requires = ["nextcloud-admin-key.service" "mysql.service"];
    script = mkAfter ''
      nextcloud-occ user:setting admin settings email ${cfg.adminEmail}
      echo '${toJSON settings}' | nextcloud-occ config:import
      # After upgrade make sure DB is up-to-date
      nextcloud-occ db:add-missing-columns -n
      nextcloud-occ db:add-missing-primary-keys -n
      nextcloud-occ db:add-missing-indices -n
      nextcloud-occ db:convert-filecache-bigint -n
    '';
  };

  virtualisation.oci-containers = {
    # Since 22.05, the default driver is podman but it doesn't work
    # with podman. It would however be nice to switch to podman.
    backend = "docker";
    containers.collabora = {
      image = "collabora/code";
      imageFile = pkgs.dockerTools.pullImage {
        imageName = "collabora/code";
        imageDigest = "sha256:aab41379baf5652832e9237fcc06a768096a5a7fccc66cf8bd4fdb06d2cbba7f";
        sha256 = "sha256-M66lynhzaOEFnE15Sy1N6lBbGDxwNw6ap+IUJAvoCLs=";
      };
      ports = ["9980:9980"];
      environment = {
        domain = "localhost";
        extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
      };
      extraOptions = ["--cap-add" "MKNOD"];
    };
  };
}
