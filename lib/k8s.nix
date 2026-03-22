{ lib, pkgs }:

{
  # Convert list of resources to multi-document YAML
  toMultiDocYAML =
    resources:
    let
      # Convert a single resource to YAML using pkgs.formats.yaml
      toYAML =
        resource:
        let
          yamlGenerator = pkgs.formats.yaml { };
          yamlFile = yamlGenerator.generate "resource.yaml" resource;
        in
        builtins.readFile yamlFile;

      # Convert all resources and join with YAML document separator
      yamlDocs = map toYAML resources;
    in
    lib.concatStringsSep "---\n" yamlDocs;
}
