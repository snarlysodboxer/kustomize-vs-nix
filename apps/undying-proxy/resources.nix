{ lib }:

{
  namespace,
  image,
  imagePullPolicy ? "IfNotPresent",
  instanceLabel,
  replicas ? 3,
  loadBalancerTCP ? "changeme",
  loadBalancerUDP ? "changeme",
  args ? [
    "--operator-namespace=\$(OPERATOR_NAMESPACE)"
    "--tcp-service-to-manage=undying-proxy-tcp"
    "--udp-service-to-manage=undying-proxy-udp"
    "--metrics-authed=false"
    "--metrics-secure=false"
    "--metrics-bind-address=:8080"
    "--health-probe-bind-address=:8081"
    "--zap-devel=false"
    "--zap-stacktrace-level=panic"
  ],
}:

# Return ordered list of resources matching Kustomize output order
[
  {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
  }

  {
    apiVersion = "apiextensions.k8s.io/v1";
    kind = "CustomResourceDefinition";
    metadata = {
      name = "undyingproxies.proxy.sfact.io";
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
      annotations = {
        "controller-gen.kubebuilder.io/version" = "v0.15.0";
      };
    };
    spec = {
      group = "proxy.sfact.io";
      names = {
        kind = "UnDyingProxy";
        listKind = "UnDyingProxyList";
        plural = "undyingproxies";
        singular = "undyingproxy";
      };
      scope = "Namespaced";
      versions = [
        {
          additionalPrinterColumns = [
            {
              jsonPath = ".status.ready";
              name = "Ready";
              type = "boolean";
            }
            {
              jsonPath = ".spec.udp.listenPort";
              name = "ListenUDP";
              type = "number";
            }
            {
              jsonPath = ".spec.tcp.listenPort";
              name = "ListenTCP";
              type = "number";
            }
          ];
          name = "v1alpha1";
          schema = {
            openAPIV3Schema = {
              description = "UnDyingProxy is the Schema for the undyingproxies API";
              properties = {
                apiVersion = {
                  description = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
                  type = "string";
                };
                kind = {
                  description = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
                  type = "string";
                };
                metadata = {
                  type = "object";
                };
                spec = {
                  description = "UnDyingProxySpec defines the desired state of UnDyingProxy";
                  properties = {
                    tcp = {
                      description = "TCP defines a TCP port forwarder";
                      properties = {
                        listenPort = {
                          description = "ListenPort is the port to listen on";
                          type = "integer";
                        };
                        targetHost = {
                          description = "TargetHost is the address to forward to, IP or DNS resolvable name";
                          type = "string";
                        };
                        targetPort = {
                          description = "TargetPort is the port to forward to";
                          type = "integer";
                        };
                      };
                      required = [
                        "listenPort"
                        "targetHost"
                        "targetPort"
                      ];
                      type = "object";
                    };
                    udp = {
                      description = "TODO make these immutable?, better yet, support mutability";
                      properties = {
                        listenPort = {
                          description = "ListenPort is the port to listen on";
                          type = "integer";
                        };
                        readTimeoutSeconds = {
                          description = "ReadTimeoutSeconds is the timeout for reading from the client and target. Defaults to 30 seconds.";
                          type = "integer";
                        };
                        targetHost = {
                          description = "TargetHost is the address to forward to, IP or DNS resolvable name";
                          type = "string";
                        };
                        targetPort = {
                          description = "TargetPort is the port to forward to";
                          type = "integer";
                        };
                        writeTimeoutSeconds = {
                          description = "WriteTimeoutSeconds is the timeout for writing to the client and target. Defaults to 5 seconds.";
                          type = "integer";
                        };
                      };
                      required = [
                        "listenPort"
                        "targetHost"
                        "targetPort"
                      ];
                      type = "object";
                    };
                  };
                  type = "object";
                };
                status = {
                  description = "UnDyingProxyStatus defines the observed state of UnDyingProxy";
                  properties = {
                    ready = {
                      description = "Ready is true when the proxy is ready to accept connections";
                      type = "boolean";
                    };
                  };
                  required = [ "ready" ];
                  type = "object";
                };
              };
              type = "object";
            };
          };
          served = true;
          storage = true;
          subresources = {
            status = { };
          };
        }
      ];
    };
  }

  {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = {
      name = "undying-proxy";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
  }

  {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "Role";
    metadata = {
      name = "undying-proxy";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    rules = [
      {
        apiGroups = [ "" ];
        resources = [ "services" ];
        verbs = [
          "create"
          "delete"
          "get"
          "list"
          "patch"
          "update"
          "watch"
        ];
      }
      {
        apiGroups = [ "" ];
        resources = [ "services/status" ];
        verbs = [ "get" ];
      }
      {
        apiGroups = [ "proxy.sfact.io" ];
        resources = [ "undyingproxies" ];
        verbs = [
          "create"
          "delete"
          "get"
          "list"
          "patch"
          "update"
          "watch"
        ];
      }
      {
        apiGroups = [ "proxy.sfact.io" ];
        resources = [ "undyingproxies/finalizers" ];
        verbs = [ "update" ];
      }
      {
        apiGroups = [ "proxy.sfact.io" ];
        resources = [ "undyingproxies/status" ];
        verbs = [
          "get"
          "patch"
          "update"
        ];
      }
    ];
  }

  {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "RoleBinding";
    metadata = {
      name = "undying-proxy";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io";
      kind = "Role";
      name = "undying-proxy";
    };
    subjects = [
      {
        kind = "ServiceAccount";
        name = "undying-proxy";
        inherit namespace;
      }
    ];
  }

  {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "undying-proxy-tcp";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = loadBalancerTCP;
      selector = {
        app = "undying-proxy";
      };
      externalTrafficPolicy = "Local";
      ports = [
        {
          name = "lowest-port";
          port = 3000;
          targetPort = 3000;
          protocol = "TCP";
        }
        {
          name = "highest-port";
          port = 29999;
          targetPort = 29999;
          protocol = "TCP";
        }
      ];
    };
  }

  {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "undying-proxy-udp";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = loadBalancerUDP;
      selector = {
        app = "undying-proxy";
      };
      externalTrafficPolicy = "Local";
      ports = [
        {
          name = "lowest-port";
          port = 3000;
          targetPort = 3000;
          protocol = "UDP";
        }
        {
          name = "highest-port";
          port = 29999;
          targetPort = 29999;
          protocol = "UDP";
        }
      ];
    };
  }

  {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "undying-proxy";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
      annotations = {
        "cluster-autoscaler.kubernetes.io/safe-to-evict" = "false";
      };
    };
    spec = {
      inherit replicas;
      selector = {
        matchLabels = {
          app = "undying-proxy";
        };
      };
      strategy = {
        type = "RollingUpdate";
        rollingUpdate = {
          maxUnavailable = 1;
          maxSurge = 2;
        };
      };
      template = {
        metadata = {
          labels = {
            app = "undying-proxy";
          };
          annotations = {
            "kubectl.kubernetes.io/default-container" = "manager";
            "cluster-autoscaler.kubernetes.io/safe-to-evict" = "false";
          };
        };
        spec = {
          serviceAccountName = "undying-proxy";
          securityContext = {
            runAsNonRoot = true;
            seccompProfile = {
              type = "RuntimeDefault";
            };
          };
          containers = [
            {
              name = "undying-proxy";
              inherit image imagePullPolicy args;
              command = [ "/manager" ];
              env = [
                {
                  name = "OPERATOR_NAMESPACE";
                  valueFrom = {
                    fieldRef = {
                      fieldPath = "metadata.namespace";
                    };
                  };
                }
              ];
              ports = [
                {
                  name = "metrics";
                  containerPort = 8080;
                  protocol = "TCP";
                }
              ];
              resources = {
                requests = {
                  cpu = "0.4";
                  memory = "128Mi";
                };
                limits = {
                  cpu = "1.5";
                  memory = "256Mi";
                };
              };
              livenessProbe = {
                periodSeconds = 20;
                initialDelaySeconds = 15;
                httpGet = {
                  port = 8081;
                  path = "/healthz";
                };
              };
              readinessProbe = {
                periodSeconds = 10;
                initialDelaySeconds = 5;
                httpGet = {
                  port = 8081;
                  path = "/readyz";
                };
              };
              securityContext = {
                allowPrivilegeEscalation = false;
                capabilities = {
                  drop = [ "ALL" ];
                };
              };
            }
          ];
          terminationGracePeriodSeconds = 10;
          affinity = {
            podAntiAffinity = {
              requiredDuringSchedulingIgnoredDuringExecution = [
                {
                  topologyKey = "kubernetes.io/hostname";
                  labelSelector = {
                    matchLabels = {
                      app = "undying-proxy";
                    };
                  };
                }
              ];
            };
          };
        };
      };
    };
  }

  {
    apiVersion = "policy/v1";
    kind = "PodDisruptionBudget";
    metadata = {
      name = "undying-proxy";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    spec = {
      minAvailable = 2;
      selector = {
        matchLabels = {
          app = "undying-proxy";
        };
      };
    };
  }

  {
    apiVersion = "monitoring.googleapis.com/v1";
    kind = "PodMonitoring";
    metadata = {
      name = "undying-proxy";
      inherit namespace;
      labels = {
        app = "undying-proxy";
        "app.kubernetes.io/instance" = instanceLabel;
      };
    };
    spec = {
      selector = {
        matchLabels = {
          app = "undying-proxy";
        };
      };
      endpoints = [
        {
          port = "metrics";
          interval = "30s";
        }
      ];
    };
  }

]
