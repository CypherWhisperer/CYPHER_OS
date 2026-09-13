# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/kubernetes.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.devops;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.kubernetes.enable) {

    # ── k3s Service ────────────────────────────────────────────────────────────
    services.k3s = {
      enable = true;
      role = "server";

      extraFlags = toString [
        "--write-kubeconfig-mode 644"
        # "--disable traefik"   # uncomment to use your own ingress controller
        # "--disable servicelb" # uncomment to use MetalLB or no load balancer
      ];
    };

    # Start k3s manually — saves resources when not doing Kubernetes work.
    # sudo systemctl start k3s
    systemd.services.k3s.wantedBy = lib.mkForce [ ];

    environment.systemPackages = with pkgs; [
      # ── Core Kubernetes CLI ───────────────────────────────────────────────────
      kubectl # universal Kubernetes CLI; works with any cluster
      kubernetes-helm # Helm v3 — the de-facto Kubernetes package manager
      kubernetes-helm-wrapped # PATH-wrapped variant; required in some scripting contexts

      # ── TUI cluster manager ───────────────────────────────────────────────────
      # k9s: terminal UI for Kubernetes. Real-time view of pods, deployments,
      # services, logs, events. The fastest day-to-day cluster navigation tool.
      # Run: k9s
      k9s

      # ── Local dev cluster tools ───────────────────────────────────────────────
      k3d # run k3s inside Docker; fast, lightweight, consistent with the k3s service above
      kind # Kubernetes IN Docker; upstream k8s, slower but more production-faithful

      # ── Cluster utilities ─────────────────────────────────────────────────────
      kail # multi-pod log streamer; replaces multiple `kubectl logs -f` windows
      kubectl-view-secret # decode Kubernetes secrets to plaintext in one command
      kubeprompt # k8s context/namespace in shell prompt (compare with p10k segment)

      # ── DEFERRED — operational/advanced tools ────────────────────────────────
      # kubernetes                  # full upstream binaries (kubeadm, kubelet) — not needed with k3s
      # kubernetes-metrics-server   # Metrics Server for `kubectl top` and HPA; deploy as manifest, not host package
      # kubernetes-polaris          # best-practices manifest scanner — useful once writing real workloads
      # kubernetes-validate         # manifest schema validation — good CI gate
      # kubernetes-code-generator   # scaffolds Go client libraries for custom CRDs — only if writing controllers/operators in Go
      # kubernetes-controller-tools # generate CRD manifests and RBAC from Go types — same territory as above
      # clusterctl                  # Cluster API; manages cloud cluster lifecycle
      # kns                         # namespace switcher; quick context/namespace switching in shell
      # kube-review                 # test ValidatingWebhookConfigurations locally
      # kubeaudit                   # security auditor for live clusters
      # kubeshark                   # Wireshark-style network traffic analyzer for k8s
      # kubestroyer                 # penetration testing tool for Kubernetes clusters
      # kubeclarity                 # vulnerability scanner for k8s workloads; overlaps with trivy in containers.nix
      # seabird                     # Electron GUI Kubernetes client
      # gitlab-kas                  # GitLab Kubernetes Agent Server; only if using GitLab CI/CD with Kubernetes
      # arion                       # Nix-native Docker Compose alternative — revisit when familiar with both
      # kubectl-ai                  # AI-assisted kubectl — build muscle memory first
      # kubernix                    # run Kubernetes with Nix for node environments; interesting for experiments, niche use case
    ];

  };
}
