{ config, lib, pkgs, ... }:

{
  # thx to https://xyno.space/post/nix-store-nfs :3

  boot.initrd.availableKernelModules = [
    # FS stuff
    "nfsv4"
    "overlay"
  ];

  fileSystems."/" = lib.mkImageMediaOverride
    {
      fsType = "tmpfs";
      options = [ "mode=0755" "size=32G" ]; # we do need a big tmpfs as root, container images gotta go somewhere
    };
  fileSystems."/nix/.rw-store" = lib.mkImageMediaOverride {
    fsType = "tmpfs";
    options = [ "mode=0755" "size=8G" ];
    neededForBoot = true;
  };
  fileSystems."/nix/.ro-store" = lib.mkImageMediaOverride
    {
      fsType = "nfs4";
      device = "192.168.2.192:/export/nix-store";
      options = [ "ro" ];
      neededForBoot = true;
    };
  fileSystems."/nix/store" = lib.mkImageMediaOverride
    {
      fsType = "overlay";
      device = "overlay";
      options = [
        "lowerdir=/nix/.ro-store"
        "upperdir=/nix/.rw-store/store"
        "workdir=/nix/.rw-store/work"
      ];
      depends = [
        "/nix/.ro-store"
        "/nix/.rw-store/store"
        "/nix/.rw-store/work"
      ];
    };
  boot.initrd.network.enable = true;
  boot.initrd.network.flushBeforeStage2 = false; # required for NFS /nix/store in initrd
}
