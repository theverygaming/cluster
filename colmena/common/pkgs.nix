{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ neofetch ];

  virtualisation.docker.enable = true;
}
