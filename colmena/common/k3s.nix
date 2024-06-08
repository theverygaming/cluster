{ deployment, config, pkgs, ... }:

{
  networking.firewall.enable = false; # cursed but makes things work...

  services.k3s = (if (config.networking.hostName != "clustercontrol") then {
    serverAddr = "https://clustercontrol.local:6443";
    role = "agent";
  } else {
    role = "server";
    disableAgent = true;
  }) // {
    enable = true;
    tokenFile = "/var/lib/autoprov-client/keys/k3s";
  };

  environment.systemPackages = [ pkgs.k3s ];
}
