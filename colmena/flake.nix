{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ ];
        };
      };

      defaults = {
        imports = [
          ./common
        ];
      };

      clustercontrol = {
        deployment = {
          targetHost = "clustercontrol.local";
          targetUser = "user";
        };
        imports = [
          ./nodes/clustercontrol
        ];
      };

      fx6300 = {
        deployment = {
          targetHost = "fx6300.local";
          targetUser = "user";
        };
        imports = [
          ./nodes/fx6300
        ];
      };

      optiplex755 = {
        deployment = {
          targetHost = "optiplex755.local";
          targetUser = "user";
        };
        imports = [
          ./nodes/optiplex755
        ];
      };
    };
  };
}
