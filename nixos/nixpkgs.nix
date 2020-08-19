import ./nixpkgs {
  overlays =
    [ (self: super:
        {
          sde-builder = rec {
            sdeVersion = "9.1.1";

            kernelVersion = "4.14.151";
            ## Determine the hash with:
            ## nix-prefetch-url  http://cdn.kernel.org/pub/linux/kernel/v4.x/linux-<kernelVersion>.tar.xz 
            kernelHash = "1bizb1wwni5r4m5i0mrsqbc5qw73lwrfrdadm09vbfz9ir19qlgz";

            ### Location of the directory that contains the inputs to the build:
            ## bf-sde-<sdeVersion>.tar
            ## bf-reference-bsp-<sdeVersion>.tar
            ## tools.tar (Barefoot Academy tools)
            ## kernel-config
            ### The kernel configuration can be copied from a
            ### running system with "zcat /proc/config.gz"
            inputPath = ./bf-sde-build-input;
          };
        })
    ] ++ import ./overlays/overlays.nix;
}
