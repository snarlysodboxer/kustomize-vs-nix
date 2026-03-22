{
  lib,
  mkResources,
  components,
}:

{
  prod = mkResources {
    namespace = "reloader";
    instanceLabel = "reloader";
    image = "ghcr.io/stakater/reloader:v1.0.121";
    requestsCpu = "100m";
    requestsMemory = "256Mi";
    limitsCpu = "1";
    limitsMemory = "512Mi";
  };

  staging1 = lib.pipe (mkResources {
    namespace = "reloader";
    instanceLabel = "reloader";
    image = "ghcr.io/stakater/reloader:v1.0.152";
    args = [ "--reload-strategy=annotations" ];
    requestsCpu = "100m";
    requestsMemory = "256Mi";
    limitsCpu = "1";
    limitsMemory = "512Mi";
  }) [ components.withSpotNodePool ];

  staging2 = lib.pipe (mkResources {
    namespace = "reloader";
    instanceLabel = "reloader";
    image = "ghcr.io/stakater/reloader:v1.0.152";
    args = [ "--reload-strategy=annotations" ];
  }) [ components.withSpotNodePool ];
}
