{ lib }:

{
  # Component: spot-node-pool
  # Adds node selector and tolerations for spot workload nodes
  withSpotNodePool =
    resources:
    map (
      resource:
      if resource.kind == "Deployment" then
        lib.recursiveUpdate resource {
          spec.template.spec = {
            nodeSelector = {
              "my-domain.com/node-pool-name" = "spot-workloads";
            };
            tolerations = [
              {
                key = "my-domain.com/node-pool-name";
                operator = "Equal";
                value = "spot-workloads";
                effect = "NoSchedule";
              }
            ];
          };
        }
      else
        resource
    ) resources;

  # Component: fastcpu-node-pool
  # Adds node selector and tolerations for fast CPU nodes
  withFastCpuNodePool =
    resources:
    map (
      resource:
      if resource.kind == "Deployment" then
        lib.recursiveUpdate resource {
          spec.template.spec = {
            nodeSelector = {
              "my-domain.com/node-pool-name" = "fastcpu-workloads";
            };
            tolerations = [
              {
                key = "my-domain.com/node-pool-name";
                operator = "Equal";
                value = "fastcpu-workloads";
                effect = "NoSchedule";
              }
            ];
          };
        }
      else
        resource
    ) resources;

  # Component: one-replica
  # Scales deployment to 1 replica and reduces resources
  # Also removes deployment strategy and pod affinity
  withSingleReplica =
    resources:
    map (
      resource:
      if resource.kind == "Deployment" then
        let
          # Remove strategy and affinity fields
          spec = lib.filterAttrs (n: v: n != "strategy") resource.spec;
          templateSpec = lib.filterAttrs (n: v: n != "affinity") resource.spec.template.spec;
        in
        resource
        // {
          spec = spec // {
            replicas = 1;
            template = resource.spec.template // {
              spec = templateSpec // {
                containers = map (
                  container:
                  container
                  // {
                    resources = {
                      requests = {
                        cpu = "500m";
                        memory = "256Mi";
                      };
                      limits = {
                        cpu = "1";
                        memory = "1.5Gi";
                      };
                    };
                  }
                ) resource.spec.template.spec.containers;
              };
            };
          };
        }
      else
        resource
    ) resources;
}
