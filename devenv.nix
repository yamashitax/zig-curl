{ pkgs, zigpkgs, ... }:

{
  packages = [ pkgs.zls zigpkgs.packages."${pkgs.system}".master ];
}
