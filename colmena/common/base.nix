{ config, lib, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # users
  users.users."user" = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "wheel" "plugdev" "dialout" "docker" ] ++ (lib.optional config.networking.networkmanager.enable "networkmanager");
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGEXP+YFeEihXZGZjtvbthkNayMOXwMLLtugMS7YAdS" ]; # TODO: ssh key from https://github.com/theverygaming.keys?
  };
  nix.settings.trusted-users = lib.mkIf (config.nix.enable) [ "user" ];

  nix.settings.experimental-features = lib.mkIf (config.nix.enable) [ "nix-command" "flakes" ];

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "user";

  # reduce size
  environment.defaultPackages = [ ];
  xdg.icons.enable = false;
  xdg.mime.enable = false;
  xdg.sounds.enable = false;
  documentation.man.enable = false;
  nix.settings.auto-optimise-store = lib.mkIf (config.nix.enable) true;
  nix.gc = lib.mkIf (config.nix.enable) {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 1d";
  };

  # no need for logs on disk
  fileSystems."/var/log" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=1G" "mode=755" ];
  };

  # /tmp should def be a tmpfs :3
  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=1G" "mode=777" ];
  };

  system.stateVersion = "24.05";
}
