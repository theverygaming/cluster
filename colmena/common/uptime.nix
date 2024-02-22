{ deployment, config, pkgs, ... }:

{
  users.users."uptime-curl" = {
    isSystemUser = true;
    description = "user for uptime-curl service";
    group = "uptime-curl";
    extraGroups = [ "keys" ];
  };
  users.groups.uptime-curl = {};

  systemd.services.uptime-curl = {
    enable = true;
    description = "Periodically send a GET request";
    after = [ "network.target" ];
    requires = [ "uptime-url-key.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "uptime-curl";
    };
    path = [
      pkgs.curl
    ];
    script = ''
      curl "$(cat /var/run/keys/uptime-url)"
    '';
  };

  systemd.timers.uptime-curl = {
    enable = true;
    wantedBy = [ "timers.target" ];
    partOf = [ "uptime-curl.service" ];
    timerConfig = {
      OnCalendar = [ "*:0/30" ];
      Persistent = true;
    };
  };

  deployment.keys.uptime-url = {
    keyCommand = [ "cat" "../secrets/uptime/${config.networking.hostName}" ];
    user = "uptime-curl";
    group = "uptime-curl";
    permissions = "0400";
  };
}
