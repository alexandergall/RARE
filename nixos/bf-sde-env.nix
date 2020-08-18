with import ./nixpkgs.nix;

stdenv.mkDerivation rec {
  name = "bf-sde-environment";
  buildInputs = [
    getopt which python sysctl utillinux
    bf-sde
  ] ++
  ( with python3Packages;
    [ jsl jsonschema packaging ]);
  ## chmod u+w $SDE
  ## chmod u+w $SDE_INSTALL/share/p4/targets/tofino
  ## chmod u+w $SDE_INSTALL/share/tofinopd
  shellHook = ''
    export SDE=/home/gall/RARE/nixos/foo-sde
    export SDE_INSTALL=$SDE/install

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
