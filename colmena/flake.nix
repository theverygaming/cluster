{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
          targetHost = "clustercontrol.local";
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
