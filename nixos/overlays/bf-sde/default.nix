{ stdenv }:

stdenv.mkDerivation rec {
  name = "bf-sde-${version}";
  version = "9.1.1";

  src = builtins.path {
    name = "bf-sde-${version}.tar";
    path = "/home/gall/bf-sde-${version}.tar";
  };
  bsp = builtins.path {
    name = "bf-reference-bsp-${version}.tar";
    path = "/home/gall/bf-reference-bsp-${version}.tar";
  };

  buildInputs = [ ];
  
  buildPhase = ''
    cd p4studio_build
    ./p4studio_build.py -j8 --use-profile all_profile \
      --bsp-path ${bsp}
   '';

}
