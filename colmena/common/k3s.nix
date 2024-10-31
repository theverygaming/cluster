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
    extraFlags = [
      # things you can disable:
      # - coredns
      # - traefik
      # - local-storage
      # - metrics-server
      # - servicelb
      "--disable=traefik"
      "--disable=local-storage"
      "--disable=servicelb"
    ];
    role = "server";
    clusterInit = true; # this node initializes embedded etcd
  }) // {
    enable = true;
    gracefulNodeShutdown = {
      enable = true;
      shutdownGracePeriodCriticalPods = "30s";
      shutdownGracePeriod = "3m";
    };
  };

  environment.systemPackages = [
    pkgs.k3s

    # for longhorn (deployed on k3s)
    pkgs.nfs-utils
    pkgs.openiscsi
  ];
}
