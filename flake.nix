{
  description = "Kubernetes manifests for all applications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Shared utilities and components
      k8s = import ./lib/k8s.nix { inherit lib pkgs; };
      components = import ./lib/components.nix { inherit lib; };

      # Load all apps
      apps = {
        undying-proxy = import ./apps/undying-proxy {
          inherit lib components;
        };
        reloader = import ./apps/reloader {
          inherit lib components;
        };
      };

      # Build a manifest derivation from a list of resources
      mkManifest =
        app: env: resources:
        pkgs.runCommand "${env}-${app}.yaml" { } ''
          cat > $out <<'EOF'
          ${k8s.toMultiDocYAML resources}
          EOF
        '';

      # Build all packages dynamically: { prod_undying-proxy, prod_reloader, ... }
      buildPackages = lib.flatten (
        lib.mapAttrsToList (
          appName: appDef:
          lib.mapAttrsToList (envName: resources: {
            name = "${envName}_${appName}";
            value = mkManifest appName envName resources;
          }) appDef.environments
        ) apps
      );

    in
    {
      # Packages organized by environment_app pattern
      packages.${system} = lib.listToAttrs buildPackages;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          kustomize
          kubectl
          kfilt
          icdiff
          yq-go
          nixfmt-rfc-style
        ];
      };
    };
}
