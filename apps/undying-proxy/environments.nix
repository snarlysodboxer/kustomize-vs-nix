{
  lib,
  mkResources,
  components,
}:

{
  prod = lib.pipe (mkResources {
    namespace = "undying-proxy-123-123-123-123";
    instanceLabel = "undying-proxy-123-123-123-123";
    image = "my-prod-registry.io/undying-proxy:v0.1.0";
    loadBalancerTCP = "123.123.123.123";
    loadBalancerUDP = "123.123.123.123";
  }) [ components.withFastCpuNodePool ];

  staging1 = lib.pipe (mkResources {
    namespace = "undying-proxy-234-234-234-234";
    instanceLabel = "undying-proxy-234-234-234-234";
    image = "my-dev-registry.io/undying-proxy:v0.1.1";
    loadBalancerTCP = "234.234.234.234";
    loadBalancerUDP = "234.234.234.234";
  }) [ components.withSpotNodePool ];

  staging2 =
    lib.pipe
      (mkResources {
        namespace = "undying-proxy-345-345-345-345";
        instanceLabel = "undying-proxy-345-345-345-345";
        image = "my-dev-registry.io/undying-proxy:vlatest";
        imagePullPolicy = "Always";
        loadBalancerTCP = "345.345.345.345";
        loadBalancerUDP = "345.345.345.345";
        args = [
          "--operator-namespace=\$(OPERATOR_NAMESPACE)"
          "--tcp-service-to-manage=undying-proxy-tcp"
          "--udp-service-to-manage=undying-proxy-udp"
          "--metrics-authed=false"
          "--metrics-secure=false"
          "--metrics-bind-address=:8080"
          "--health-probe-bind-address=:8081"
          "--zap-devel=true"
          "--zap-stacktrace-level=debug"
        ];
      })
      [
        components.withSpotNodePool
        components.withSingleReplica
      ];
}
