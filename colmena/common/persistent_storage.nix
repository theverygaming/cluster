{ config, ... }:

{
  # requirements for the persistent volume:
  # - has UUID "3fc36f0f-f789-48b2-929c-676a1214643b"
  # - storage directory exists

  # flash ipxe.usb
  # sudo fdisk /dev/sdX -> create ext4 partition
  # sudo mkfs.ext4 /dev/sdXX
  # sudo e2fsck -f /dev/sdXX
  # sudo tune2fs /dev/sdXX -U "3fc36f0f-f789-48b2-929c-676a1214643b"
  # sudo mount /dev/sdXX /mnt
  # sudo mkdir /mnt/storage

  # now create...
  # k3s.env and k3s.secret -> described in k3s.nix
  # chown root:root k3s.*
  # chmod 644 k3s.env
  # chmod 600 k3s.secret

  fileSystems = { } // (if (config.networking.hostName != "clustercontrol") then {
    "/mnt/persistent" =
      {
        device = "/dev/disk/by-uuid/3fc36f0f-f789-48b2-929c-676a1214643b";
        fsType = "ext4";
      };
    "/etc/rancher/node" = {
      depends = [
        "/mnt/persistent"
      ];
      device = "/mnt/persistent/storage";
      fsType = "none";
      options = [
        "bind"
      ];
    };

  } else { });
}
