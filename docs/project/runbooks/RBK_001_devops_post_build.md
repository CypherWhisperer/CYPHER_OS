# Runbook: Post-Rebuild Verification — DevOps Module Expansion

**Last verified:** 2026-05-28
**Host:** `cypher-nixos`
**Module:** `modules/devops/` (_all submodules_)
**Trigger:** Reactive — run after first `nixos-rebuild switch` with the expanded devops module set
**Estimated time:** ~15 minutes

---

## When To Use This Runbook

Use after the first `nixos-rebuild switch` following the 2026-05-28 devops module expansion. Verifies that all four new modules (_cloud, observability, networking, cicd_) activated cleanly and that existing modules are unaffected.

---

## Prerequisites

- Active NixOS session on `cypher-nixos`
- `nixos-rebuild switch` completed without errors
- Docker daemon running (`systemctl status docker`)
- The following flags set in host profile (_adjust to what you actually enabled_):
  ```nix
  cypher-os.devops.cloud.enable     = true;
  cypher-os.devops.cloud.aws.enable = true;
  cypher-os.devops.observability.enable            = true;
  cypher-os.devops.observability.prometheus.enable = true;
  cypher-os.devops.observability.grafana.enable    = true;
  cypher-os.devops.observability.loki.enable       = true;
  cypher-os.devops.networking.enable       = true;
  cypher-os.devops.networking.caddy.enable = true;
  cypher-os.devops.cicd.enable = true;
  ```

---

## Procedure

### Step 1 — Verify existing modules are unaffected

```bash
docker --version
podman --version
kubectl version --client
tofu version
psql --version
redis-cli --version
```

Expected output: version strings for all six tools.
If any fail: check `journalctl -b | grep -i 'error\|failed'` for activation errors.

---

### Step 2 — Verify cloud CLIs

```bash
aws --version
eksctl version
aws-vault --version
```

Expected output:
```
aws-cli/2.x.x ...
0.x.x
aws-vault v7.x.x
```

If `aws` is missing: confirm `cypher-os.devops.cloud.aws.enable = true` is set and rebuild was clean.

---

### Step 3 — Verify CI/CD tools

```bash
gh --version
act --version
actionlint --version
```

Expected output: version strings for all three.

---

### Step 4 — Verify `mkcert` moved correctly

```bash
mkcert --version
```

Expected output: `v1.x.x`
If missing: it was previously in `secrets.nix`; confirm `cypher-os.devops.networking.enable = true`.

---

### Step 5 — Verify Prometheus is running

```bash
systemctl status prometheus
curl -s http://localhost:9090/-/ready
```

Expected output: service `active (running)` and HTTP response `Prometheus Server is Ready.`

---

### Step 6 — Verify node exporter is running

```bash
systemctl status prometheus-node-exporter
curl -s http://localhost:9100/metrics | head -5
```

Expected output: service `active (running)` and prometheus metric lines beginning with `#`.

---

### Step 7 — Verify Grafana is running

```bash
systemctl status grafana
curl -s http://localhost:3001/api/health
```

Expected output: service `active (running)` and JSON `{"commit":"...","database":"ok","version":"..."}`.

If Grafana returns a non-200: check `journalctl -u grafana -n 50`.

---

### Step 8 — Verify Loki and Promtail are running

```bash
systemctl status loki
systemctl status promtail
curl -s http://localhost:3100/ready
```

Expected output: both services `active (running)` and HTTP response `ready`.

If `promtail` unit is not found: the NixOS module name may differ in your pinned nixpkgs revision. Check with:
```bash
systemctl list-units | grep -i promtail
```
If absent, add `pkgs.promtail` to systemPackages and run it as a user service, or update nixpkgs.

---

### Step 9 — Verify Caddy is running

```bash
systemctl status caddy
curl -s http://localhost:2019/config/
```

Expected output: service `active (running)` and a JSON Caddy config response.

---

### Step 10 — Verify Grafana datasources are provisioned

Open a browser and navigate to `http://localhost:3001`. Log in with `admin`/`admin` (change the password when prompted).

Navigate to: **Connections → Data sources**

Expected: Prometheus and Loki data sources listed. Click each and use **Test** to confirm connectivity.

If Prometheus test fails: verify `services.prometheus.port = 9090` matches the URL in the provisioned datasource.

---

### Step 11 — Final: check for evaluation warnings

```bash
journalctl -b | grep -i 'nix\|warning\|deprecated' | head -20
```

Expected: no NixOS evaluation warnings related to the devops modules.

---

## Rollback

If the rebuild caused a boot failure or service crash loop:

```bash
# Boot into the previous generation from the GRUB menu,
# then roll back:
sudo nixos-rebuild switch --rollback
```

For partial failures (services fail but system is otherwise healthy), disable the offending module flag in the profile and rebuild:

```bash
# Example: disable observability temporarily
# Set cypher-os.devops.observability.enable = false in profile
sudo nixos-rebuild switch --flake .#nixos-gnome
```

---

## Related

- Module docs: `modules/devops/docs/`
- Journal: [DevOps and Cloud Tooling Session](../../development/journal/2026_05_28_devops_and_cloud_tooling.md)

---

<!--
METADATA
Created:    2026-05-28
Updated:    2026-05-28
Tested by:  Cypher Whisperer
-->
