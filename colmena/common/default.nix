{ ... }:

{
  imports =
    [
      ./base.nix
      ./k3s.nix
      ./persistent_storage.nix
      #./slurm.nix
      ./tinysystem.nix
      ./uptime.nix
    ];
}
