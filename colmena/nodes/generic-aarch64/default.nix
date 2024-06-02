{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./aarch64-common.nix
    ];

  networking.hostName = "generic-aarch64-node";
}
