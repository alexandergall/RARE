let
  pkgs = import ../../nixpkgs.nix;
  derivations = import ./inputs.nix pkgs;
in
with pkgs;
with builtins;
concatStringsSep " " (map toString derivations)
