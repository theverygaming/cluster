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
    tokenFile = "/tmp/k3skey";
  };

  #systemd.services.k3s.requisite = [ "k3s-key.service" ];

  #deployment.keys.k3s = {
  #  keyCommand = [ "cat" "../secrets/k3s.key" ];
  #  user = "root";
  #  group = "root";
  #  permissions = "0400";
  #};

  environment.systemPackages = [ pkgs.k3s ];
}
