{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./nfsNixStore.nix
    ];

  networking.hostName = "generic-x86-64-node";

  # On some systems that are so minimal stuff breaks... and that includes GPU stuff
  boot.kernelParams = [
    "nomodeset"
  ];
}
