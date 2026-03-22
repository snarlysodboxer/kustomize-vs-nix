{ lib, components }:

let
  mkResources = import ./resources.nix { inherit lib; };
  environments = import ./environments.nix {
    inherit
      lib
      mkResources
      components
      ;
  };
in
{
  inherit environments;
}
