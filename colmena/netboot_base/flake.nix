{
  description = "Netboot";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    {
      netbootSystem = { targetSystem, hostSystem, extraModules ? [ ] }:
        let
          bootableSystem = nixpkgs.lib.nixosSystem {
            system = targetSystem;
            modules = [
              ./netboot.nix
            ] ++ extraModules;
          };
          build = bootableSystem.config.system.build;
        in
        {
          webroot = nixpkgs.legacyPackages.${hostSystem}.stdenv.mkDerivation
            {
              name = "webroot";
              
              buildCommand =
                ''
                  mkdir -p "$out"
                  ln -s "${build.kernel}/bzImage" "$out/bzImage"
                  ln -s "${build.netbootRamdisk}/initrd" "$out/initrd"
                  ln -s "${build.netbootIpxeScript}/netboot.ipxe" "$out/init.ipxe"
                '';
            };
          nfsroot = build.nixStore;
          ipxe = build.ipxe;
        };
    };
}
