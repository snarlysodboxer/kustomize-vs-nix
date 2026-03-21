Please read @README.md to understand my goals with this project.

I have created the Kustomize configs that build Kubernetes objects for an example app. Please create a Nix flake with build targets that result in identical YAML output. Please build it in such a way as to be able to target different apps in different environments, e.g. undying-proxy in prod, staging1, staging2, to get the slightly different configs for each.

Notice how I have structured the Kustomize configs with bases (in the `apps` directory,) overlays, and components. Notice how we can quickly enable/disable various patches in the different overlays by including or not including various components. We need similar functionality in the Nix. The components are essentially patches that could be resused by various overlays, while the patches in the individual overlays are patches that are only for that specific overlay.

As mentioned in the readme, it would be nice to have nix build commands that output the YAML on stdout for examination and piping.

Please follow Nix best practices. Use the nixos and other MCP servers and internet as needed. Please think carefully about the best design for the Nix setup, and create a plan and let me review it. After my approval and perhaps some discussion, follow that plan and write the actual Nix code.

Please also create a Nix dev shell with the latest versions of `kustomize`, `kubectl`, `kfilt`, `icdiff`, and the Nix linter in it. If you want to add `yq` and/or similar for development, that's fine too. - It's probably best to do this first thing, to then have the tools for development and comparison.

DO NOT run `kubectl` in any way or form. Simply redirect the output to files for comparison.

Make sure the Nix builds correctly and passes the official nixfmt-rfc-style linter.

When you think you're ready, compare the output of both approaches by running the three `kustomize build <overlay><app> > kustomize-<environment>.yaml` commands as well as the three `nix build ... > nix-<environment>.yaml` commands and then comparing the resulting files. The output should be identical. Use `icdiff` for comparison. If the order of YAML keys is causing a problem with comparison and you don't have an easy solution, let me know, and we'll setup predictable-yaml which will reorder the YAML keys in a predictable way.

After you're finished with that, please update the @README.md to add instructions for using the Nix. If you have any thoughts on the pros and cons of each approach, go ahead and add those as well.

I will do the git committing, but feel free to suggest a multiline commit message describing your changes.
