{ pkgs, netboot, ... }:
let
  extraModules = [
    ../../common
  ];

  netX86 = netboot.netbootSystem {
    targetSystem = "x86_64-linux";
    hostSystem = pkgs.stdenv.hostPlatform.system;
    inherit extraModules;
  };
  netAarch64 = netboot.netbootSystem {
    targetSystem = "aarch64-linux";
    hostSystem = pkgs.stdenv.hostPlatform.system;
    inherit extraModules;
  };
in
{

  fileSystems."/export/nix-store-x86_64-linux" = {
    device = "${netX86.nfsroot}";
    options = [ "bind" ];
  };

  fileSystems."/export/nix-store-aarch64-linux" = {
    device = "${netAarch64.nfsroot}";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export/nix-store-x86_64-linux (ro,insecure)
    /export/nix-store-aarch64-linux (ro,insecure)
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
                <li><a href="/x86_64-linux-ipxe">x86_64-linux ipxe</a></li>
                <li><a href="/aarch64-linux">aarch64-linux files</a></li>
                <li><a href="/aarch64-linux-ipxe">aarch64-linux ipxe</a></li>
              </ul> 
            </body>
          </html>
          HTML 200
      }

      handle_path /x86_64-linux* {
        file_server browse
        root * ${netX86.webroot}
      }

      handle_path /x86_64-linux-ipxe* {
        file_server browse
        root * ${netX86.ipxe}
      }

      handle_path /aarch64-linux* {
        file_server browse
        root * ${netAarch64.webroot}
      }

      handle_path /aarch64-linux-ipxe* {
        file_server browse
        root * ${netAarch64.ipxe}
      }
    '';
  };
  networking.firewall.allowedTCPPorts = [ 8081 ];
}
