{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  nix.enable = lib.mkIf (config.networking.hostName != "clustercontrol") false;
}
