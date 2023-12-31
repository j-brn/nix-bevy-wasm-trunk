# nix-bevy-wasm-trunk

[![deploy](https://github.com/j-brn/nix-bevy-wasm-trunk/actions/workflows/deploy.yml/badge.svg)](https://github.com/j-brn/nix-bevy-wasm-trunk/actions/workflows/deploy.yml)
[![test](https://github.com/j-brn/nix-bevy-wasm-trunk/actions/workflows/test.yml/badge.svg)](https://github.com/j-brn/nix-bevy-wasm-trunk/actions/workflows/test.yml)

[Bevy](https://github.com/bevyengine/bevy) breakout example with nix build and github pages deployment

## Prerequisites

- [Nix](https://github.com/NixOS/nix) has to be installed and
  [flakes and the experimental nix command have to be enabled](https://nixos.wiki/wiki/Flakes#Enable_flakes)
- (optional) install and setup [direnv](https://direnv.net/) to automatically enter the dev shell in this directory

## Usage

- `nix build` to build
- `nix flake check` to run tests
- `nix develop` to enter the dev shell (happens automatically when using direnv)
- `trunk serve` to start the development server

