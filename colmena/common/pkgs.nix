{ pkgs, ... }:

{
  # TODO: move this
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
    };
  };


  environment.systemPackages = with pkgs; [ neofetch ];

  virtualisation.docker.enable = true;

}
