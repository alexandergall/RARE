import ./nixpkgs {
  overlays =
    [ (self: super:
        {
          sde-builder = rec {
            sdeVersion = "9.1.1";
            sdeTarball = builtins.path rec {
              name = "bf-sde-${sdeVersion}.tar";
              path = ./bf-sde + "/${name}";
            };
            sdeToolsTarball = builtins.path {
              name = "bf-sde-tools.tar";
              path = ./bf-sde/ba-102-tools-2019-09-09.tar;
            };
            bspTarball = builtins.path rec {
              name = "bf-reference-bsp-${sdeVersion}.tar";
              path = ./bf-sde + "/${name}";
            };
            kernelConfig = builtins.path {
              name = "custom-kernel-config";
              path = ./bf-sde/kernel-config;
            };
            kernelVersion = "4.14.151";
            ## nix-prefetch-url  http://cdn.kernel.org/pub/linux/kernel/v4.x/linux-<kernel-version>.tar.xz 
            kernelHash = "1bizb1wwni5r4m5i0mrsqbc5qw73lwrfrdadm09vbfz9ir19qlgz";
          };
        })
    ] ++ import ./overlays/overlays.nix;
}
