{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nano
    cpio
    kexec-tools
  ];

  environment.variables = {
    EDITOR = "nano";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # users
  users.users.nixos = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGEXP+YFeEihXZGZjtvbthkNayMOXwMLLtugMS7YAdS" ];
  };
}
