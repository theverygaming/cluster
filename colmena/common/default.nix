{ ... }:

{
  imports =
    [
      ./autoprov.nix
      ./avahi.nix
      ./base.nix
      ./k3s.nix
      #./slurm.nix
      ./tinysystem.nix
      ./uptime.nix
    ];
}
