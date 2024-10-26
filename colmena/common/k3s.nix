{ deployment, config, pkgs, ... }:

let
  isNotControlPlane = config.networking.hostName != "clustercontrol";
in
{
  networking.firewall.enable = false; # cursed but makes things work...

  services.k3s = (if (isNotControlPlane) then {
    serverAddr = "https://192.168.2.192:6443";
    role = "agent";
    environmentFile = "/mnt/persistent/k3s.env"; # specified in the env file: K3S_NODE_NAME
    tokenFile = "/mnt/persistent/k3s.secret";
  } else {
    role = "server";
    disableAgent = true;
    tokenFile = "/root/keys/k3s";
  }) // {
    enable = true;
    #gracefulNodeShutdown.enable = true;  # not available in nixpkgs d5b23b1e24a9860f65973c5757e10af291a7b691 (Jul 22nd 2024)
  };

  environment.systemPackages = [
    pkgs.k3s
  ];

  # for longhorn (deployed on k3s)
  services.openiscsi = {
    enable = isNotControlPlane;
    name = "iqn.linux-iscsi." + config.networking.hostName;
  };
}
