{ pkgs, ... }:

{
  imports = [
    ./installscript.nix
  ];

  environment.systemPackages = [ pkgs.nano ];
  environment.variables = {
    EDITOR = "nano";
  };

  services.getty.helpLine = ''
    |----------------------------------------------------------------------|
    | You can now use the node-install script to install NixOS on the node |
    |----------------------------------------------------------------------|
  '';
}
