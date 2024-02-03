#!/usr/bin/env bash
cd "${0%/*}"
nix flake update
nix build .#nixosConfigurations.installer.config.system.build.isoImage
