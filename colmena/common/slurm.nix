{ deployment, config, ... }:

{
  networking.firewall.allowedTCPPorts = (if (config.networking.hostName == "optiplex755") then [ 6817 ] else [ ]) ++ [ 6818 ];

  services.slurm = (if (config.networking.hostName == "optiplex755") then { server.enable = true; } else { }) // {
    client.enable = true;
    controlMachine = "optiplex755";
    controlAddr = "optiplex755.local";
    nodeName = [
      "optiplex755 NodeAddr=optiplex755.local CPUs=4 CoresperSocket=4 State=UNKNOWN"
      "fx6300 NodeAddr=fx6300.local CPUs=6 CoresPerSocket=6 State=UNKNOWN"
    ];
    partitionName = [
      "cluster Nodes=ALL Default=YES MaxTime=0:0:20 State=UP"
    ];
    # max log level: debug5
    extraConfig = ''
      SlurmctldDebug=verbose
      SlurmdDebug=verbose
    '';
  };

  services.munge = {
    enable = true;
    password = "/var/run/keys/munge-key";
  };

  users.users.munge.extraGroups = [ "keys" ];

  # TODO: store key persistently
  deployment.keys.munge-key = {
    text = "ehehehehehehehehehee,e,e,ehehehehe :3 :3 :3 teheee hehehe"; # must be at least 32 bytes
    user = "munge";
    group = "munge";
    permissions = "0400";
  };

}
