{ lib, pkgs, ... }:

{
  systemd.services.autoprov = {
    enable = true;
    description = "autprov";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "root";
    };
    path = [
      (pkgs.systemd.overrideAttrs (old: {
        patches = lib.lists.remove "./0006-hostnamed-localed-timedated-disable-methods-that-cha.patch" old.patches;
      }))
    ];
    script = ''
      while true
      do
        hostnamectl set-hostname "test"
        sleep 60
      done
    '';
  };
}
