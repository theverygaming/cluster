{ ... }:

{
  imports =
    [
      ./autoprov.nix
      ./avahi.nix
      ./base.nix
      ./k3s.nix
      ./pkgs.nix
      ./slurm.nix
      ./uptime.nix
    ];
}
