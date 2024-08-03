{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d5b23b1e24a9860f65973c5757e10af291a7b691";  # FIXME: pinned (to nixpkgs ~Jul 22nd 2024) because perlless breaks due to this PR: https://github.com/NixOS/nixpkgs/pull/328926
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
