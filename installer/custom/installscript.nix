{ lib, pkgs, ... }:

{
  environment.systemPackages =
    let
      nodeInstall = with pkgs;
        stdenv.mkDerivation rec {
          name = "node-install";

          unpackPhase = "true"; # we don't have a source

          buildInputs = [ bash ];

          # based on https://gist.github.com/nuxeh/35fb0eca2af4b305052ca11fe2521159
          script = writeText "node-install" ''
            #!/usr/bin/env bash
            set -e

            read -p "What should the hostname for the new system be? " HOSTNAME

            sudo fdisk -l | less
            
            echo "Detected the following devices:"
            echo
            i=0
            for device in $(sudo fdisk -l | grep "^Disk /dev" | awk "{print \$2}" | sed "s/://"); do
                echo "[$i] $device"
                i=$((i+1))
                DEVICES[$i]=$device
            done
            echo
            read -p "Which device do you wish to install on (type the ID, not the name)? " DEVICE
            DEV=''${DEVICES[$(($DEVICE+1))]}

            while true; do
              read -p "Is this a UEFI system? y/n: " UEFI
              case $UEFI in
                  [y]* ) break;;
                  [n]* ) break;;
                  * ) echo "y/n";;
              esac
            done
            read -p "How much swap space do you need in GiB (e.g. 8)? (0 means no swap) " SWAP

            read -p "Will now partition ''${DEV} with swap size ''${SWAP}GiB. Ok? Type 'go': " ANSWER

            if [ "$ANSWER" = "go" ]; then
                echo "partitioning ''${DEV}..."
                (
                  if [ "$UEFI" = "y" ]; then
                      echo g # new gpt partition table

                      echo n # new partition
                      echo 3 # partition 3
                      echo   # default start sector
                      echo +512M # size is 512M
                  else
                      echo o # new MBR parition table
                  fi

                  echo n # new partition
                  if [ "$UEFI" = "n" ]; then
                      echo p # primary
                  fi
                  echo 1 # first partition
                  echo   # default start sector
                  echo -''${SWAP}G # last N GiB

                  if [ "$SWAP" -ne "0" ]; then
                      echo n # new partition
                      if [ "$UEFI" = "n" ]; then
                          echo p # primary
                      fi
                      echo 2 # second partition
                      echo   # default start sector
                      echo   # default end sector
                  fi

                  echo t # set type
                  if [ "$UEFI" = "y" ] || [ "$SWAP" -ne "0" ]; then
                      echo 1 # first partition
                  fi
                  if [ "$UEFI" = "y" ]; then
                      echo 20 # Linux Filesystem
                  else
                      echo 83 # linux
                  fi

                  if [ "$SWAP" -ne "0" ]; then
                      echo t # set type
                      echo 2 # second partition
                      if [ "$UEFI" = "y" ]; then
                          echo 19 # Linux swap
                      else
                          echo 82 # Linux swap
                      fi
                  fi

                  if [ "$UEFI" = "y" ]; then
                      echo t # set type
                      echo 3 # third partition
                      echo 1 # EFI System
                  fi

                  echo p # print layout

                  echo w # write changes
                ) | sudo fdisk ''${DEV}
            else
                echo "cancelled."
                exit
            fi

            echo "getting created partition names..."

            i=1
            for part in $(sudo fdisk -l | grep $DEV | grep -v "," | awk '{print $1}'); do
                echo "[$i] $part"
                i=$((i+1))
                PARTITIONS[$i]=$part
            done

            P1=''${PARTITIONS[2]}
            P2=''${PARTITIONS[3]}
            P3=''${PARTITIONS[4]}

            read -p "Press enter to install NixOS." NULL

            echo "making filesystem on ''${P1}..."

            sudo mkfs.ext4 -L nixos ''${P1}
            
            if [ "$SWAP" -ne "0" ]; then
                echo "enabling swap..."
                sudo mkswap -L swap ''${P2}
                sudo swapon ''${P2}
            fi

            if [ "$UEFI" = "y" ]; then
                echo "making filesystem on ''${P3}..."
                sudo mkfs.fat -F 32 -n boot ''${P3}
            fi

            echo "mounting filesystems..."

            sudo mount /dev/disk/by-label/nixos /mnt

            if [ "$UEFI" = "y" ]; then
                sudo mkdir -p /mnt/boot/efi
                sudo mount /dev/disk/by-label/boot /mnt/boot/efi
            fi

            echo "generating NixOS configuration..."

            sudo nixos-generate-config --root /mnt

            sudo rm -f /mnt/etc/nixos/configuration.nix # we'll use flakes

            sudo tee << EOF /mnt/etc/nixos/flake.nix
            {
              inputs = {
                nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
              };

              outputs = { self, nixpkgs, ... }: {
                nixosConfigurations = {
                  "''${HOSTNAME}" = nixpkgs.lib.nixosSystem rec {
                    system = "x86_64-linux";
                    modules = [
                      ./syscfg.nix
                    ];
                  };
                };
              };
            }
            EOF

            sudo tee << EOF /mnt/etc/nixos/syscfg.nix
            { config, lib, pkgs, ... }:

            {
              imports =
                [
                  ./hardware-configuration.nix
                ];

              boot.loader.grub.enable = true;
            EOF

            if [ "$UEFI" = "y" ]; then
                sudo tee -a << EOF /mnt/etc/nixos/syscfg.nix
              boot.loader.grub.efiSupport = true;
              boot.loader.grub.efiInstallAsRemovable = true;
              boot.loader.efi.efiSysMountPoint = "/boot/efi";
            EOF
            fi

            sudo tee -a << EOF /mnt/etc/nixos/syscfg.nix
              boot.loader.grub.device = "''${DEV}";

              services.openssh = {
                enable = true;
                settings.PasswordAuthentication = false;
              };

              # Networking
              networking.hostName = "''${HOSTNAME}";
              networking.networkmanager.enable = true;

              # passwordless sudo
              security.sudo.wheelNeedsPassword = false;

              # users
              users.users."user" = {
                isNormalUser = true;
                description = "user";
                extraGroups = [ "wheel" "plugdev" "dialout" "docker" ] ++ (lib.optional config.networking.networkmanager.enable "networkmanager");

                openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGEXP+YFeEihXZGZjtvbthkNayMOXwMLLtugMS7YAdS" ]; # TODO: ssh key from https://github.com/theverygaming.keys?
              };

              # Automatically log in at the virtual consoles.
              services.getty.autologinUser = "user";

              # reduce size
              environment.defaultPackages = [];
              xdg.icons.enable  = false;
              xdg.mime.enable   = false;
              xdg.sounds.enable = false;
              documentation.man.enable = false;
              nix.settings.auto-optimise-store = true;
              nix.gc = {
                automatic = true;
                dates = "daily";
                options = "--delete-older-than 2d";
              };

              system.stateVersion = "23.11";
            }
            EOF

            sudo nixos-install --flake /mnt/etc/nixos#''${HOSTNAME}

            echo "You can now reboot. Don't forget to remove the installation media"
            echo "If you need to do any further configuration on the installed system everything is still mounted in /mnt"
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp ${script} $out/bin/node-install
            chmod +x $out/bin/node-install
          '';
        };
    in
    [ nodeInstall ];
}
