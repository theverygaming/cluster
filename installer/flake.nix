{
  # https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
  description = "Minimal NixOS installation media";
  inputs.nixpkgs.url = "nixpkgs/23.11";
  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
          ./custom
        ];
      };
    };
  };
}
