with import <nixpkgs> { overlays = import ./overlays/overlays.nix; };

stdenv.mkDerivation rec {
  name = "RARE-bf-sde-nix-environment";
  buildInputs = [
    bf-sde
  ];
}
