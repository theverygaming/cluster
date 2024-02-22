{ deployment, config, pkgs, ... }:

{
  users.users."uptime-curl" = {
    isSystemUser = true;
    description = "user for uptime-curl service";
    group = "uptime-curl";
    extraGroups = [ "keys" ];
  };
  users.groups.uptime-curl = { };

  systemd.services.uptime-curl = {
    enable = true;
    description = "Periodically send a GET request";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    requisite = [ "uptime-url-key.service" ];
    serviceConfig = {
      Type = "simple";
      User = "uptime-curl";
    };
    path = [
      pkgs.curl
    ];
    script = ''
      while true
      do
        curl "$(cat /var/run/keys/uptime-url)"
        sleep 60
      done
    '';
  };

  deployment.keys.uptime-url = {
    keyCommand = [ "cat" "../secrets/uptime/${config.networking.hostName}" ];
    user = "uptime-curl";
    group = "uptime-curl";
    permissions = "0400";
  };
}
