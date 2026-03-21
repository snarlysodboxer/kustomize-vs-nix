# Experiment comparing Kustomize vs Nix for Kubernetes object management

_I'm familiar with Kustomize for managing Kubernetes objects. I want to see what it would look like to use Nix to accomplish the same thing._

## Notes
* My starting place is some example Kustomize configs, which I would use (or more likely have ArgoCD use) like the following:
    * Deploy undying-proxy to prod:
        `kustomize build kustomize/overlays/prod/undying-proxy-123-123-123-123 | kubectl apply -f -`
    * Deploy undying-proxy to staging1:
        `kustomize build kustomize/overlays/staging1/undying-proxy-234-234-234-234 | kubectl apply -f -`
    * Deploy undying-proxy to staging2:
        `kustomize build kustomize/overlays/staging2/undying-proxy-345-345-345-345 | kubectl apply -f -`
* To get a quick idea of what's different between these three environments, start by looking in the overlay directories at the `<overlay>/<app>/kustomization.yaml` file.
* It should be noted I am not yet a Nix expert, and that I'm having Claude help me write the Nix.
* It would be nice if we could keep `nix build ...` logs/errors directed to stderr, while redirecting the resulting YAML to stdout, so that we can manually examine it, as well as pipe it into kubectl apply like we do with Kustomize.

