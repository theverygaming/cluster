{ lib, pkgs, config, ... }:

let
  sillyORMPackage = pkgs.python311Packages.buildPythonPackage rec {
    pname = "sillyorm";
    version = "0.2.0";
    pyproject = true;

    nativeBuildInputs = [
      pkgs.python311Packages.setuptools
    ];

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-7ItyPeLalI6clXfw4dTsJYUNYgwg4rWobfK9N56DA7g=";
    };
  };

  autoprovServerPackage = pkgs.stdenv.mkDerivation {
    name = "autoprov-server";
    buildInputs = [
      (pkgs.python311.withPackages (python311Packages: with python311Packages; [
        sillyORMPackage
        flask
        waitress
      ]))
      pkgs.systemd
    ];
    dontUnpack = true;
    installPhase = "install -Dm755 ${../../autoprov/autoprov-server.py} $out/bin/autoprov-server";
  };

  autoprovClientPackage = pkgs.stdenv.mkDerivation {
    name = "autoprov-client";
    buildInputs = [
      (pkgs.python311.withPackages (python311Packages: with python311Packages; [
        pkgs.python311Packages.requests
      ]))
      pkgs.systemd
    ];
    dontUnpack = true;
    installPhase = "install -Dm755 ${../../autoprov/autoprov-client.py} $out/bin/autoprov-client";
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      systemd = (prev.systemd.overrideAttrs (old: {
        patches = builtins.filter (x: (if builtins.typeOf x == "path" then builtins.baseNameOf x else "") != "0006-hostnamed-localed-timedated-disable-methods-that-cha.patch") old.patches;
      }));
    })
  ];

  systemd = {
    services.autoprov = lib.mkIf (config.networking.hostName != "clustercontrol") {
      enable = true;
      description = "Autoprov setup";
      wantedBy = [ "k3s.service" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      path = [
        autoprovClientPackage
      ];
      script = ''
        autoprov-client init
      '';
    };

    services.autoprov-ping = lib.mkIf (config.networking.hostName != "clustercontrol") {
      description = "Autoprov ping";
      wantedBy = [ "k3s.service" ];
      after = [ "autoprov.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      path = [
        autoprovClientPackage
      ];
      script = ''
        autoprov-client
      '';
    };

    timers.autoprov-ping-timer = lib.mkIf (config.networking.hostName != "clustercontrol") {
      enable = true;
      description = "autoprov-ping.service timer";
      wantedBy = [ "k3s.service" ];
      after = [ "autoprov.service" ];
      timerConfig = {
        OnBootSec = "1s";
        OnUnitActiveSec = "1m";
        Unit = "autoprov-ping.service";
      };
    };

    services.autoprov-server = lib.mkIf (config.networking.hostName == "clustercontrol") {
      enable = true;
      description = "Autoprov server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
      };
      path = [
        autoprovServerPackage
      ];
      script = ''
        autoprov-server
      '';
    };
  };
}
