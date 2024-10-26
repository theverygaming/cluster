{ config, lib, pkgs, ... }:

{
  # FIXME: on the HP t610 and Dell Wyse DX0D when the kernel switches to a different mode from text mode the terminal stops working
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
