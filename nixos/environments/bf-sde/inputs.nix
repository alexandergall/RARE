pkgs:
with pkgs;
[
  getopt which python sysctl utillinux
  bf-sde
] ++
( with python3Packages;
  [ jsl jsonschema packaging ])
