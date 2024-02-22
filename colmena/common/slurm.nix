{ deployment, config, lib, ... }:

{
  #networking.firewall.allowedTCPPorts = [ 6818 ] ++ (lib.optional (config.networking.hostName == "optiplex755") 6817);

  networking.firewall.enable = false; # cursed but makes things work...

  # TODO: is the slurm user id set somewhere or do we need to take care of syncing it on nodes?
  services.slurm = (if (config.networking.hostName == "clustercontrol") then {
    server.enable = true;
  } else { }) // {
    client.enable = true;
    controlMachine = "clustercontrol";
    controlAddr = "clustercontrol.local";
    nodeName = [
      "clustercontrol NodeAddr=clustercontrol.local CPUs=1 State=UNKNOWN"
      "fx6300 NodeAddr=fx6300.local CPUs=6 CoresPerSocket=6 State=UNKNOWN"
      "optiplex755 NodeAddr=optiplex755.local CPUs=4 CoresperSocket=4 State=UNKNOWN"
    ];
    partitionName = [
      "x86 Nodes=clustercontrol,fx6300,optiplex755 Default=YES MaxTime=1-0:0:0 State=UP"
    ];
    # max log level: debug5
    extraConfig = ''
      SlurmctldDebug=info
      SlurmdDebug=info
    '';
  };

  systemd.services.slurmd.requisite = [ "munged.service" ];

  services.munge = {
    enable = true;
    password = "/var/run/keys/munge";
  };
  systemd.services.munged.requisite = [ "munge-key.service" ];

  users.users.munge.extraGroups = [ "keys" ];

  deployment.keys.munge = {
    keyCommand = [ "cat" "../secrets/slurm.key" ];
    user = "munge";
    group = "munge";
    permissions = "0400";
  };

  # TODO: we can fix nodes being DOWN after reboot. For example this script could be run after reboot
  # sudo scontrol -dd show node $HOSTNAME | grep "Node unexpectedly rebooted" && sudo scontrol update NodeName=$HOSTNAME State=RESUME
  # https://forums.raspberrypi.com/viewtopic.php?t=252185
}
