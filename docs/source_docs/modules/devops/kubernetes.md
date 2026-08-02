# Kubernetes — `kubernetes.nix`

> Configures the k3s Kubernetes distribution as a non-autostarting NixOS system service, and installs the full Kubernetes toolchain: kubectl, Helm, local cluster runners, a TUI cluster manager, and operational utilities.

**Module path:** `modules/devops/kubernetes.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Enable `services.k3s` as a systemd service with manual start (not autostarted at boot)
- Install `kubectl`, `kubernetes-helm`, and `kubernetes-helm-wrapped`
- Install `k9s` as the primary TUI cluster manager
- Install `k3d` and `kind` as local Docker-backed cluster runners
- Install `kail`, `kubectl-view-secret`, and `kubeprompt` as cluster utilities

**Does not:**

- Manage application manifests or Helm charts — those live in project repositories
- Manage `kubeconfig` — generated at runtime by k3s, stored at `~/.kube/config`
- Install the full upstream Kubernetes binaries (`kubeadm`, `kubelet`) — not needed when running k3s
- Autostart k3s at boot — explicitly disabled to save resources when not doing Kubernetes work

---

## Evaluation Context

| Property              | Value                                                             |
| --------------------- | ----------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                    |
| Options namespace     | `cypher-os.devops.kubernetes.*`                                   |
| Imports `options.nix` | No — imported by `system.nix`                                     |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.kubernetes.enable)` |
| Profile default       | `lib.mkDefault true` — enabled by default in the devops profile   |

---

## Block Analysis

---

### Block 1 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents all service and package configuration if either `devops.enable` or `devops.kubernetes.enable` is false.

**Why is it here?** Standard CypherOS pattern. k3s in particular is a heavyweight service — it runs a control plane, a worker node, and containerd. Disabling it cleanly from the profile is important for machines where Kubernetes work is not active.

---

### Block 2 — `services.k3s`

**What is this?** NixOS `services.k3s` module configuration.

**What does it do?** Registers k3s as a systemd service in `server` role — meaning this node runs both the Kubernetes control plane (API server, scheduler, controller manager) and a worker. Passes `--write-kubeconfig-mode 644` so the generated `k3s.yaml` kubeconfig is readable without `sudo` on a single-user dev machine.

**Why k3s over full Kubernetes?** k3s is a CNCF-certified Kubernetes distribution delivered as a single ~60 MB binary. It strips alpha features, uses SQLite as its default backing store instead of etcd, and bundles containerd. It is functionally identical to upstream Kubernetes for everything relevant at the beginner and intermediate stages. The full `kubernetes` package (`kubeadm`, `kubelet`, etc.) is only needed when bootstrapping a production-grade cluster — it is DEFERRED in the package list for exactly this reason.

**Why `role = "server"` and not `"agent"`?** The `server` role runs the control plane (API server, scheduler, controller manager) alongside the worker. `agent` means worker-only, connecting to a remote control plane. On a single dev machine, `server` is the correct role.

```nix
# k3s runs as a system service. This makes it start on boot and be managed
# by systemd. For a dev machine, you may prefer manual start:
#   services.k3s.enable = true;
#   systemctl start k3s   (manual, on demand)
# vs
#   boot.startK3s = true; (automatic at boot)
# We enable the service but set it to not start automatically at boot —
# saves resources when you're not doing k8s work.

services.k3s = {
  enable = true;
  role   = "server";
  # additional flags passed to the k3s server binary.
  extraFlags = toString [
    # make generated kubeconfig world-readable so you don't need sudo every time.
    # Only do this on a single-user dev machine.
    "--write-kubeconfig-mode 644"
  ];
};
```

---

### Block 3 — `systemd.services.k3s.wantedBy = lib.mkForce []`

**What is this?** A `lib.mkForce` override of the k3s service's `wantedBy` systemd dependency.

**What does it do?** Removes k3s from the `multi-user.target` dependency chain, preventing it from starting automatically at boot. k3s must be started manually: `sudo systemctl start k3s`.

**Why is it here?** k3s is resource-intensive — it runs a full Kubernetes control plane, maintains cluster state, and holds containerd open. On a dev machine, there are long periods where no Kubernetes work is happening. Not autostarting saves meaningful CPU and memory at boot and keeps the machine responsive for other work. `lib.mkForce` is required because the NixOS `services.k3s` module sets `wantedBy = [ "multi-user.target" ]` by default; without `mkForce`, the assignment would be silently merged away.

```nix
systemd.services.k3s.wantedBy = lib.mkForce [];
```

---

### Block 4 — `environment.systemPackages`

**What is this?** The full package list for the Kubernetes toolchain.

**What does it do?** Installs all active Kubernetes tools; documents deferred and excluded tools with the three-header convention.

**Why is it here?** All Kubernetes CLI tools are user-facing binaries without daemon counterparts (except k3s itself, declared above). They could live in Home Manager, but keeping the entire Kubernetes toolchain co-located with the k3s service declaration avoids split ownership confusion.

#### Package inventory

**Core CLI:**
- `kubectl` — universal Kubernetes CLI; the single tool that works with k3s, k3d, kind, EKS, GKE, AKS — any cluster that speaks the Kubernetes API; non-negotiable
- `kubernetes-helm` — Helm v3; the de-facto package manager for Kubernetes; charts are pre-packaged manifests with configurable values; used to install ingress controllers, cert-manager, monitoring stacks, etc.
- `kubernetes-helm-wrapped` — Helm with a NixOS PATH wrapper that handles plugin binary paths correctly in scripting and automation contexts; functionally identical to `kubernetes-helm` for manual use

**TUI cluster manager:**
- `k9s` — terminal UI for Kubernetes; provides a real-time view of pods, deployments, services, logs, and events; the fastest day-to-day cluster navigation tool; notably absent from the original file and added in the 2025-05-28 session

**Local dev cluster tools:**
- `k3d` — runs k3s clusters inside Docker containers; faster startup than `kind`, consistent with the k3s service above; excellent for throwaway clusters, multi-node simulation, and CI-like local environments
- `kind` — Kubernetes IN Docker; runs upstream Kubernetes (not k3s) inside Docker; slower than k3d but more faithful to production clusters; use when you need vanilla upstream k8s behaviour

**Cluster utilities:**
- `kail` — multi-pod log streamer; streams logs from multiple pods and namespaces simultaneously; replaces the tedium of running multiple `kubectl logs -f` windows
- `kubectl-view-secret` — decodes and displays Kubernetes Secrets in plaintext; eliminates the `kubectl get secret -o jsonpath | base64 -d` pipeline
- `kubeprompt` — displays current k8s context and namespace in the shell prompt; compare with the kubectl segment in your p10k config before keeping both

**Deffered Operational / Advanced packages:**
These tools are genuinely useful but premature at the learning stage. Uncomment as you grow into them.
- `kubernetes` - full upstream Kubernetes binaries (kubeadm, kubelet, etc.). NOT needed when running k3s — k3s bundles its own versions. Only relevant if you move to a kubeadm-bootstrapped cluster or baremetal production setup.
- `kubernetes-metrics-server` - Kubernetes Metrics Server for `kubectl top` as a manifest, not a host package: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
- `kubernetes-polaris` - policy enforcement / best practices scanner. Checks your manifests against production-readiness standards (resource limits, security contexts, etc.). Great once you're writing real workloads.
- `kubernetes-validate` - validates Kubernetes manifests against the API schema before applying. Good CI check. Useful when your manifests grow complex.
- `kubernetes-code-generator` -  scaffolds Go client libraries for custom CRDs. Only relevant if you're writing Kubernetes controllers/operators in Go.
- `kubernetes-controller-tools` - generate CRD manifests and RBAC from Go types. Same as above — controller development territory.
- `clusterctl` - Cluster API CLI. Manages the lifecycle of entire clusters (create, upgrade, delete cloud k8s clusters declaratively). Relevant when you move beyond local dev into cloud cluster management.
- `kns` - namespace switcher. Quick context/namespace switching in the shell. `kubectl config set-context --current --namespace=<n>` covers this for now.
- `kube-review` - tests Kubernetes ValidatingWebhookConfigurations locally. Very niche — only needed if you're writing admission webhooks.
- `kubeaudit` - security auditor for live clusters. Checks for missing resource limits, privileged containers, capabilities, etc. Very useful in production.
- `kubeshark` - real-time network traffic analyzer for Kubernetes. Like Wireshark for your cluster's internal traffic. Powerful debugging tool.
- `kubeclarity` - penetration testing tool for Kubernetes clusters. Useful for understanding attack surfaces once you have a cluster to test.
- `kubeclarity` - container image and code vulnerability scanning specifically for k8s workloads. Use trivy (in containers.nix) first — overlapping scope.
- `seabird` - GUI Kubernetes client (Electron). Alternative to k9s (TUI) or the web dashboard. Try it if you prefer a GUI workflow over kubectl.
- `gitlab-kas` - GitLab Kubernetes Agent Server. Only relevant if you're running GitLab CI/CD pipelines that deploy to Kubernetes clusters via the agent.
- `arion` - Docker Compose-style tool backed by Nix. Declare services as Nix modules instead of YAML. Long-term this fits CypherOS philosophy well. Worth revisiting once you're comfortable with both Nix and Compose.
- `kubectl-ai` - AI-assisted kubectl. Generates kubectl commands from natural language. Fun but not foundational — build the kubectl muscle memory first.
- `kubernix` - run Kubernetes using Nix for the node environment. Interesting for Nix+k8s integration experiments. Very niche.

##### FIRST TIME SETUP:
```bash

# k3s starts as a systemd service. Access the cluster:
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config
kubectl get nodes   # should show your node as Ready

# For k3d clusters (doesn't use the k3s service above — runs in Docker):
k3d cluster create dev
kubectl get nodes

#   For kind clusters:
kind create cluster --name dev
kubectl get nodes

# VERIFYING THE SETUP:
kubectl version --client
helm version
k3d version
kind version
kail --version
```

---

## Dependencies

**Imported files:** None directly.

**NixOS options set by this file:**
- `services.k3s.*`
- `systemd.services.k3s.wantedBy`
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.kubectl`, `pkgs.kubernetes-helm`, `pkgs.kubernetes-helm-wrapped`
- `pkgs.k9s`
- `pkgs.k3d`, `pkgs.kind`
- `pkgs.kail`, `pkgs.kubectl-view-secret`, `pkgs.kubeprompt`

**Runtime dependencies:**
- `k3d` and `kind` require Docker to be running; ensure `cypher-os.devops.containers.enable = true`

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.kubernetes.enable` | `bool` | `true` (profile default) | Registers k3s service; installs full toolchain |

---

## Design Notes

- k3s is registered but not autostarted. The deliberate friction of `sudo systemctl start k3s` before Kubernetes work is a feature during the learning phase — it makes the boundary between "doing Kubernetes work" and "not doing Kubernetes work" explicit.
- `k3d` and `kind` are both included despite overlapping in function. The distinction: k3d is faster and consistent with k3s; kind is slower but runs upstream Kubernetes. Use k3d for iteration speed; use kind when you need to test against vanilla k8s API behaviour.
- `kubernetes-helm` and `kubernetes-helm-wrapped` both install the `helm` binary. In practice you will only ever type `helm`. The wrapped version exists for NixOS-specific PATH handling in scripting; having both is harmless and avoids having to add the wrapped version later when a script needs it.
- `k9s` was absent from the original module despite appearing in the learning notes as a recommended package. Added in the 2025-05-28 session.

---

## Known Limitations

- k3s bundles its own version of containerd; this is separate from the containerd that Docker uses. The two do not interfere, but disk space is used twice.
- The `--write-kubeconfig-mode 644` flag makes the kubeconfig world-readable. This is only appropriate on a single-user machine. On a shared machine, remove this flag and use `sudo` or group-based access to the kubeconfig.
- `kubeprompt` and the p10k kubectl segment may conflict if both are active. Review your p10k config before enabling both.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Aggregator          | `./system.nix`               |
| Profile default     | `modules/profile/system.nix` |
