let
  pkgs = import ../../nixpkgs.nix;
in
with pkgs;
stdenv.mkDerivation rec {
  name = "bf-sde-environment";
  buildInputs = import ./inputs.nix pkgs;
  shellHook = ''
    export SDE=/home/gall/RARE/nixos/foo-sde
    export SDE_INSTALL=$SDE/install

    PATH=$PATH:$SDE_INSTALL/bin:$SDE

    ## Make sudo available through PATH
    . /etc/os-release
    if [ $ID == "nixos" ]; then
      PATH=$PATH:/run/wrappers/bin
    else
      PATH=$PATH:/usr/bin
    fi
    sudo mkdir -p /mnt
  '';
}
