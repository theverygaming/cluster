{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # 2024-10-31: switching from 24.05 to unstable because significant improvements were made to k3s in unstable
    netboot = {
      url = "github:theverygaming/nixos-netboot-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, netboot, ... }: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ ];
        };
        specialArgs = { inherit netboot; };
      };

      clustercontrol = {
        deployment = {
          targetHost = "192.168.2.192";
          targetUser = "user";
        };
        imports = [
          ./nodes/clustercontrol
          ./common
        ];
      };
    };
  };
}
