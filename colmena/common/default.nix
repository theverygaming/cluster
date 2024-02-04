{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./pkgs.nix
    ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Networking
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
  nix.settings.trusted-users = [ "user" ];

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "user";

  # reduce size
  environment.defaultPackages = [ ];
  xdg.icons.enable = false;
  xdg.mime.enable = false;
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
