{ config, lib, pkgs, modulesPath, ... }:

{
  boot.initrd.availableKernelModules = [
    # to be sorted lmao
    "ahci"
    "ohci_pci"
    "ehci_pci"
    "pata_atiixp"
    "usb_storage"
    "usbhid"
    "sd_mod"
    # required for NFS boot
    "nfs"
    "nfsv4"
    "overlay"
    # network cards
    "e1000" # common
    "e1000e" # common
    "r8169" # common
    "bnx2" # HP Proliant DL380 G7 iirc
    "alx" # i forgor
    "tg3" # for the BCM57781 in my HP t610
  ];
  # for NFS boot
  boot.initrd.supportedFilesystems = [ "nfs" "nfsv4" "overlay" ];
  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.enableRedistributableFirmware = true; # we do want firmware meow
}
