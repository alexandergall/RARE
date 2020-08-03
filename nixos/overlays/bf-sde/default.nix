## To test: nix-shell --pure -E 'with import <nixpkgs> { overlays = import ./overlays/overlays.nix; }; bf-sde' --command "export out=/tmp/foo; return"
{ stdenv, writeText, gmp, glibc, python, python3, linux_4_14,
  pythonPackages, pkg-config, file, thrift, openssl, boost, grpc,
  protobuf, zlib, libpcap_1_8, libusb, curl
  ## Debug
  , breakpointHook
  , strace
  }:

let
    version = "9.1.1";
    profile = writeText "bf-studio-profile"
      ''
      # SDE_VERSION : ${version}
      custom_profile:
        # Global flags to configure
        global_configure_options: '''

        # SDE components to be installed
        packages:
          - bf-syslibs:
            - bf_syslibs_configure_options: '''
          - bf-utils:
            - bf_utils_configure_options: '''
          - bf-diags:
            - bf_diags_configure_options: "--with-libpcap=${libpcap_1_8}"
          - bf-drivers:
              - bf_drivers_configure_options: '''
              - bf-runtime

        # Third party source packages to be installed
        package_dependencies:
          - grpc
          - thrift

        # Tofino architecture
        tofino_architecture: tofino
      '';
in
stdenv.mkDerivation rec {
  inherit version;
  name = "bf-sde-${version}";

  src = builtins.path {
    name = "bf-sde-${version}.tar";
    path = "/home/gall/bf-sde-${version}.tar";
  };
  ## FIXME: use archive and untar during build
  bsp = builtins.path {
    name = "bf-reference-bsp-${version}.tar";
    path = "/home/gall/bf-reference-bsp-${version}";
  };

  nativeBuildInputs = [ breakpointHook ];
  
  buildInputs = [ python python3 linux_4_14.dev pkg-config file thrift openssl boost grpc protobuf zlib
                  ## bf-diags
                  libpcap_1_8
                  ## bf-platforms
                  libusb curl
                  ## Debug
                  strace ] ++
                (with pythonPackages; [ pip pyyaml six packaging jsl jsonschema tenjin ]);

  # unpackPhase = ''
  #   set -x
  #   mv bf-sde-9.1.1.bck bf-sde-9.1.1
  #   cd bf-sde-9.1.1
  #   set +x
  # '';
  
  buildPhase = ''
    fixup() {
      archive=$1
      dir=$(basename $archive .tgz)

      echo "Fixing up $archive"
      rm -rf $dir
      tar xf $1
      cd $dir
      
      while shift; do
        echo $1
        $1
      done
      
      for f in $(find . -type f -name configure); do
        if grep /usr/bin/file $f >/dev/null; then
          cmd="substituteInPlace $f --replace /usr/bin/file ${file}/bin/file"
          echo $cmd
          $cmd
        fi
      done

      patchShebangs .
      
      cd ..
      tar cf $archive $dir
      rm -rf $dir
    }

    patchElf() {
      local archive=$1

      echo "Patching ELF dependencies in $archive"
      rm -rf tmp
      mkdir tmp
      cd tmp
      tar xf ../$1
      cd *
      
      for f in $(find . -type f -exec file {} \; | grep -i elf | cut -d' ' -f1 | sed -e 's/:$//'); do
        echo $f
        patchelf --set-interpreter ${glibc}/lib/ld-linux* $f
        case $f in
          *p4c-build-logs)
            patchelf --set-rpath ${zlib}/lib $f
            ;;
          *p4i-9.1.1-0.linux)
            patchelf --set-rpath ${stdenv.cc.cc.lib}/lib64 $f
            ;;
          *p4obfuscator)
            patchelf --set-rpath ${stdenv.cc.cc.lib}/lib64:${gmp}/lib $f
            ;;
        esac
      done
      
      for f in *; do
        if [[ $f =~ (.tar|.tgz) ]]; then
          patchElf $f
        fi
      done

      patchShebangs .
      
      cd ..
      tar cjf ../$archive *
      cd ..
      rm -rf tmp
    }
    
    fixup packages/bf-drivers-${version}.tgz
    fixup packages/bf-syslibs-${version}.tgz
    
    ## judy/libedit/klish (erroneously?) add $lt_sysroot to the include path, which results in
    ## a path with two leading slashes. The Nix gcc-wrapper considers this a
    ## "bad path" when $NIX_ENFORCE_PURITY is set, which is the case
    ## for nix-build
    ## but not fore nix-shell (even with the --pure flag)
    fixup packages/bf-utils-${version}.tgz \
      "substituteInPlace third-party/judy-1.0.5/configure --replace I\$lt_sysroot/ I" \
      "substituteInPlace third-party/libedit-3.1/configure --replace I\$lt_sysroot/ I" \
      "substituteInPlace third-party/klish/configure --replace I\$lt_sysroot/ I" \
      
    fixup packages/bf-diags-${version}.tgz \
      "substituteInPlace third-party/libcrafter/configure --replace withval/include/net/bpf.h withval/include/pcap.h" \
      "chmod u+x p4-build/tools/*.py"

    patchElf packages/p4-compilers-*
    patchElf packages/p4i-*
    patchElf packages/p4o-*

    cd p4studio_build
    cp ${profile} profiles/custom_profile.yaml
    patchShebangs .

    ## sudo is not needed in the build environment
    substituteInPlace p4studio_build.py --replace sudo ""
    ## Pick up PKG_CONFIG_PATH from the build environment
    substituteInPlace p4studio_build.py --replace PKG_CONFIG_PATH= 'PKG_CONFIG_PATH=$PKG_CONFIG_PATH:'

    ./p4studio_build.py -j4 --os-detail NixOS_19.03 --use-profile custom_profile \
      --bsp-path ${bsp} --skip-os-check --skip-dependencies \
      --skip-kernelheader-check --skip-dependencies-check \
      --KDIR ${linux_4_14.dev}/lib/modules/*/build

    cd ..
   '';

  preFixup = ''
    set -x
    oldcd=$(pwd)
    cd $out
    for f in install/bin/* install/lib/*; do
      if file $f | grep ELF >/dev/null; then
        oldPath=$(patchelf --print-rpath $f 2>/dev/null || true)
        if [[ "$oldPath" =~ /build/ ]]; then
          echo "Fixing up RPATH for $f"
          newPath=$(echo $oldPath | sed -e 's!/build/bf-sde-${version}/install/lib!'$out'/install/lib!')
          patchelf --set-rpath $newPath $f
	fi
      fi
    done
    cd $oldcd
    set +x
  '';
  
  installPhase = ''
    mkdir $out
    rm -rf build packages pkgsrc
    tar cf - . | (cd $out && tar xf -)
  '';
}
