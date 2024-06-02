#!/usr/bin/env bash
cd "${0%/*}"
nix flake update
nix build -v .#nixosConfigurations.tiny.config.system.build.isoImage
