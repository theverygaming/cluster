{ pkgs, netboot, ... }:
let
  extraModules = [
    ../../common
    ../generic-perlless-system
  ];

  netX86 = netboot.netboot {
    targetSystem = "x86_64-linux";
    hostSystem = pkgs.stdenv.hostPlatform.system;
    netbootUrlbase = "http://192.168.2.192:8081/x86_64-linux";
    rootDiskSize = "2000M";
    extraModules = extraModules ++ [
      ../generic-x86-64
    ];
  };
  /*netAarch64 = netboot.netboot {
    targetSystem = "aarch64-linux";
    hostSystem = pkgs.stdenv.hostPlatform.system;
    netbootUrlbase = "http://192.168.2.192:8081/aarch64-linux";
    rootDiskSize = "100M";
    inherit extraModules;
  };*/
in
{
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
