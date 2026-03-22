{ lib }:

{
  namespace,
  image,
  imagePullPolicy ? "IfNotPresent",
  instanceLabel,
  args ? [
    "--log-format=json"
    "--reload-strategy=annotations"
  ],
  requestsCpu ? "10m",
  requestsMemory ? "128Mi",
  limitsCpu ? "1",
  limitsMemory ? "128Mi",
}:

# Return ordered list of resources matching Kustomize output order
[
  # 1. Namespace
  {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = namespace;
      labels = {
        app = "reloader";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
  }

  # 2. ServiceAccount
  {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = {
      name = "reloader";
      inherit namespace;
      labels = {
        app = "reloader";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    imagePullSecrets = [
      {
        name = "my-registry-credentials";
      }
    ];
  }

  # 3. ClusterRole
  {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "ClusterRole";
    metadata = {
      name = "reloader";
      inherit namespace;
      labels = {
        app = "reloader";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    rules = [
      {
        apiGroups = [ "" ];
        resources = [
          "secrets"
          "configmaps"
        ];
        verbs = [
          "list"
          "get"
          "watch"
        ];
      }
      {
        apiGroups = [ "apps" ];
        resources = [
          "deployments"
          "daemonsets"
          "statefulsets"
        ];
        verbs = [
          "list"
          "get"
          "update"
          "patch"
        ];
      }
      {
        apiGroups = [ "extensions" ];
        resources = [
          "deployments"
          "daemonsets"
        ];
        verbs = [
          "list"
          "get"
          "update"
          "patch"
        ];
      }
      {
        apiGroups = [ "batch" ];
        resources = [ "cronjobs" ];
        verbs = [
          "list"
          "get"
        ];
      }
      {
        apiGroups = [ "batch" ];
        resources = [ "jobs" ];
        verbs = [ "create" ];
      }
      {
        apiGroups = [ "" ];
        resources = [ "events" ];
        verbs = [
          "create"
          "patch"
        ];
      }
    ];
  }

  # 4. ClusterRoleBinding
  {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "ClusterRoleBinding";
    metadata = {
      name = "reloader";
      inherit namespace;
      labels = {
        app = "reloader";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io";
      kind = "ClusterRole";
      name = "reloader";
    };
    subjects = [
      {
        kind = "ServiceAccount";
        name = "reloader";
        inherit namespace;
      }
    ];
  }

  # 5. Service
  {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "reloader";
      inherit namespace;
      labels = {
        app = "reloader";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    spec = {
      type = "ClusterIP";
      selector = {
        app = "reloader";
      };
      ports = [
        {
          name = "metrics";
          port = 9090;
          targetPort = "http";
          protocol = "TCP";
        }
      ];
    };
  }

  # 6. Deployment
  {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "reloader";
      inherit namespace;
      labels = {
        app = "reloader";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          app = "reloader";
        };
      };
      template = {
        metadata = {
          labels = {
            app = "reloader";
          };
        };
        spec = {
          containers = [
            {
              name = "reloader";
              inherit image imagePullPolicy args;
              env = [
                {
                  name = "GOMAXPROCS";
                  valueFrom = {
                    resourceFieldRef = {
                      resource = "limits.cpu";
                    };
                  };
                }
                {
                  name = "GOMEMLIMIT";
                  valueFrom = {
                    resourceFieldRef = {
                      resource = "limits.memory";
                    };
                  };
                }
              ];
              ports = [
                {
                  name = "http";
                  containerPort = 9090;
                }
              ];
              livenessProbe = {
                periodSeconds = 10;
                timeoutSeconds = 5;
                successThreshold = 1;
                failureThreshold = 5;
                initialDelaySeconds = 10;
                httpGet = {
                  port = "http";
                  path = "/metrics";
                };
              };
              readinessProbe = {
                periodSeconds = 10;
                timeoutSeconds = 5;
                successThreshold = 1;
                failureThreshold = 5;
                initialDelaySeconds = 10;
                httpGet = {
                  port = "http";
                  path = "/metrics";
                };
              };
              resources = {
                requests = {
                  cpu = requestsCpu;
                  memory = requestsMemory;
                };
                limits = {
                  cpu = limitsCpu;
                  memory = limitsMemory;
                };
              };
            }
          ];
          serviceAccountName = "reloader";
          securityContext = {
            runAsNonRoot = true;
            runAsUser = 65534;
            seccompProfile = {
              type = "RuntimeDefault";
            };
          };
        };
      };
    };
  }
]
