{ pkgs, netboot, ... }:
let
  extraModules = [
    ../../common
  ];

  netX86 = netboot.netboot {
    targetSystem = "x86_64-linux";
    hostSystem = pkgs.stdenv.hostPlatform.system;
    netbootUrlbase = "http://192.168.2.192:8081/x86_64-linux";
    useSquashfs = false;
    extraModules = extraModules ++ [
      ../generic-x86-64
    ];
  };
  /*netAarch64 = netboot.netboot {
    targetSystem = "aarch64-linux";
    hostSystem = pkgs.stdenv.hostPlatform.system;
    netbootUrlbase = "http://192.168.2.192:8081/aarch64-linux";
    useSquashfs = false;
    inherit extraModules;
  };*/
in
{
  fileSystems."/export/nix-store" = {
    device = "/nix/store";
    options = [ "bind" ];
  };
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export/nix-store (ro,insecure)
  '';

  services.caddy = {
    enable = true;
    virtualHosts.":8081".extraConfig = ''
      encode gzip
      handle_path /* {
        header Content-Type text/html
        respond <<HTML
          <html>
            <head>
              <title>netboot</title>
            </head>
            <body>
              <ul>
                <li><a href="/x86_64-linux">x86_64-linux files</a></li>
                <li><a href="/aarch64-linux">aarch64-linux files</a></li>
              </ul> 
            </body>
          </html>
          HTML 200
      }

      handle_path /x86_64-linux* {
        file_server browse
        root * ${netX86.webroot}
      }

      #handle_path /aarch64-linux* {
      #  file_server browse
      #  root * ''${netAarch64.webroot}
      #}
    '';
  };
  networking.firewall.allowedTCPPorts = [ 8081 ];
}
