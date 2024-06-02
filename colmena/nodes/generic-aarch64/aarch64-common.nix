{ config, lib, pkgs, ... }:

{
  boot.kernelParams = [
    "keep_bootcon"
    "nofb"
    "nomodeset"
  ];
}
