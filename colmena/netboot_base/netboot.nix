# Copyright (c) 2003-2024 Eelco Dolstra and the Nixpkgs/NixOS contributors

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# This module creates netboot media containing the given NixOS
# configuration.

{ config, lib, pkgs, ... }:

with lib;

{
  options = {

    netboot.storeContents = mkOption {
      example = literalExpression "[ pkgs.stdenv ]";
      description = ''
        This option lists additional derivations to be included in the
        Nix store in the generated netboot image.
      '';
    };

  };

  config = {
    # Don't build the GRUB menu builder script, since we don't need it
    # here and it causes a cyclic dependency.
    boot.loader.grub.enable = false;

    # !!! Hack - attributes expected by other modules.
    environment.systemPackages = [ pkgs.grub2_efi ]
      ++ (lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [ pkgs.grub2 pkgs.syslinux ]);


    # thx to https://xyno.space/post/nix-store-nfs :3

    fileSystems."/" = mkImageMediaOverride
      {
        fsType = "tmpfs";
        options = [ "mode=0755" "size=8G" ];
      };

    fileSystems."/nix/.rw-store" = mkImageMediaOverride {
      fsType = "tmpfs";
      options = [ "mode=0755" "size=8G" ];
      neededForBoot = true;
    };

    fileSystems."/nix/.ro-store" = mkImageMediaOverride
      {
        fsType = "nfs4";
        device = "192.168.2.192:/export/nix-store-${pkgs.stdenv.hostPlatform.system}";
        options = [ "ro" ];
        neededForBoot = true;
      };

    fileSystems."/nix/store" = mkImageMediaOverride
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
    networking.useDHCP = lib.mkForce true;

    boot.initrd.supportedFilesystems = [ "nfsv4" "overlay" ];

    # list of kernel modules: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/top-level/linux-kernels.nix
    boot.initrd.availableKernelModules = [
      # filesystems
      "nfsv4"
      "overlay"
      # network cards
      "e1000"
      "e1000e"
      "r8169"
      "alx"
    ];
    boot.initrd.kernelModules = [ ];

    # Closures to be copied to the Nix store, namely the init
    # script and the top-level system configuration directory.
    netboot.storeContents =
      [ config.system.build.toplevel ];

    # build the nix store directory
    system.build.nixStore =
      let
        storeContents = config.netboot.storeContents;
      in
      pkgs.stdenv.mkDerivation
        {
          name = "nix-store-dir";

          buildCommand =
            ''
              closureInfo=${pkgs.closureInfo { rootPaths = storeContents; }}

              # Also include a manifest of the closures in a format suitable
              # for nix-store --load-db.
              cp $closureInfo/registration nix-path-registration

              mkdir $out

              # copy store
              cp -r nix-path-registration $(cat $closureInfo/store-paths) $out
            '';
        };

    system.build.ipxe = pkgs.ipxe.override {
      embedScript = pkgs.stdenv.mkDerivation {
        name = "ipxe-embedscript";

        buildCommand = ''
          cat <<EOF > $out
          #!ipxe
          dhcp
          set cmdline boot.shell_on_fail # boot.trace
          chain http://192.168.2.192:8081/${pkgs.stdenv.hostPlatform.system}/init.ipxe
          EOF
        '';
      };
    };

    # Create the initrd (cursed as fuck rn, donno how i would use _just_ config.system.build.initialRamdisk)
    system.build.netbootRamdisk = pkgs.makeInitrdNG {
      inherit (config.boot.initrd) compressor;
      prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

      # refuses to work without any contents specified?
      contents =
        [
          {
            object = pkgs.stdenv.mkDerivation { name = "empty"; buildCommand = "touch $out"; };
            symlink = "/nothing";
          }
        ];
    };

    system.build.netbootIpxeScript = pkgs.writeTextDir "netboot.ipxe" ''
      #!ipxe
      # Use the cmdline variable to allow the user to specify custom kernel params
      # when chainloading this script from other iPXE scripts like netboot.xyz
      kernel ${pkgs.stdenv.hostPlatform.linux-kernel.target} initrd=initrd init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} ''${cmdline}
      initrd initrd
      boot
    '';

    boot.loader.timeout = 10;

    boot.postBootCommands =
      ''
        # After booting, register the contents of the Nix store
        # in the Nix database in the tmpfs.
        ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration

        # nixos-rebuild also requires a "system" profile and an
        # /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';
  };
}
