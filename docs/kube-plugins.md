# Useful plugins
- https://github.com/kvaps/kubectl-node-shell
- https://github.com/pragaonj/ingress-rule-updater
- https://github.com/ryane/kfilt
- https://github.com/corneliusweig/rakkess (access-matrix)
- https://github.com/knight42/kubectl-blame (see who changed)
- https://github.com/ahmetb/kubectl-cond (read conditions)
- https://github.com/corneliusweig/konfig (split configs)
- https://github.com/aquasecurity/kubectl-who-can
- https://github.com/gabeduke/kubectl-iexec?tab=readme-ov-file
- https://github.com/talos-labs/kubectl-example
- https://github.com/cnrancher/kube-explorer
- https://github.com/bonnefoa/kubectl-fzf
  


# Installed
- https://github.com/davidB/kubectl-view-allocations
- https://github.com/kubernetes-sigs/krew-index/blob/master/plugins/debug-shell.yaml
- https://github.com/itaysk/kubectl-neat


```bash
kubectl krew install explore
kubectl krew install debug-shell
kubectl krew install neat
kubectl krew install view-allocations
kubectl krew install fuzzy
kubectl krew install example
krew install iexec
```

---

## Custom fzf shell functions (ipick replacement, darwin/arm64 safe)

### `.zsh_kube_fuzzy.sh` — interactive resource operations

| Command   | Args              | Description                                      |
|-----------|-------------------|--------------------------------------------------|
| `kfl`     | `[ns\|-A]`        | Fuzzy pick pod → stream logs (multi-container)   |
| `kfe`     | `[ns\|-A]`        | Fuzzy pick pod → exec shell (bash → sh fallback) |
| `kfd`     | `[ns\|-A] [type]` | Fuzzy pick resource → describe                   |
| `kfcr`     | `[--dry-run] [ns]`| Fuzzy kubectl create: file or resource type       |
| `kfimp`   | `[--dry-run] [ns]`| Fuzzy imperative: kubectl run / kubectl expose    |
| `kfrm`    | `[ns\|-A]`        | Fuzzy pick any resource → delete (with confirm)   |
| `kfsec`   | `[ns\|-A]`        | Fuzzy pick secret → base64-decode all keys        |
| `kfcm`    | `[ns\|-A]`        | Fuzzy pick configmap → view yaml                  |
| `kfctx`   |                   | Fuzzy switch kubectl context                      |
| `kfns`    |                   | Fuzzy switch namespace                            |

Namespace arg: omit=current, `-A`=all, `my-ns`=specific
