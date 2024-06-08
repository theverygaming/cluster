{ modulesPath, lib, pkgs, ... }:

{
  imports =
    [
      "${modulesPath}/profiles/perlless.nix"
    ];

  boot.postBootCommands = lib.mkForce "";
  environment.systemPackages = lib.mkForce [
    pkgs.busybox
    pkgs.bash
    pkgs.systemd # systemctl, journalctl etc.
    pkgs.k3s
  ];
}
