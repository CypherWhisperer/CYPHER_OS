# modules/devops/secrets.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    #./vault-contained.nix
    ./vault.nix
  ];

  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.secrets.enable) {

    # ── sops-nix ───────────────────────────────────────────────────────────────
    # Uncomment once sops-nix is added to flake.nix inputs and imported in the
    # host configuration. See the module source documentation for the full
    # first-time setup procedure (key generation, .sops.yaml, secret declaration).
    #
    # sops = {
    #   defaultSopsFile  = ../../secrets/secrets.yaml;
    #   age.keyFile      = "/home/cypher-whisperer/.config/sops/age/keys.txt";
    #   age.generateKey  = false;
    #
    #   # secrets: declare which secrets to decrypt and where to place them.
    #   # Each key becomes a file under /run/secrets/<key>.
    #   # Example:
    #   # secrets.example_api_key = {
    #   #   sopsFile = ../../secrets/api-keys.yaml;
    #   #   owner = "cypher-whisperer";  # who can read /run/secrets/example_api_key
    #   #   mode = "0400";               # permissions (owner read-only)
    #   # };
    # };

    environment.systemPackages = with pkgs; [

      # ── SOPS ──────────────────────────────────────────────────────────────────
      # Secrets OPerationS — encrypts/decrypts secret files using age, GPG, or
      # cloud KMS backends. The age backend is simplest for self-hosted use.
      # Edit secrets in-place (encrypted on save): sops secrets/my-secret.yaml
      sops

      # ── age ───────────────────────────────────────────────────────────────────
      # Modern file encryption tool; the recommended SOPS backend here.
      # Generate a key pair: age-keygen -o ~/.config/sops/age/keys.txt
      age

      # ── gnupg ─────────────────────────────────────────────────────────────────
      # GPG implementation. Use age for SOPS; keep gnupg for git commit signing
      # and verifying signed releases/packages.
      gnupg

      # ── Bitwarden Secrets Manager CLI ─────────────────────────────────────────
      # bws: CLI for Bitwarden Secrets Manager (machine secrets, not the password
      # vault). A lighter-weight Vault alternative for injecting secrets into
      # scripts and CI pipelines. Pairs well with the Proton ecosystem boundary —
      # use for any secret that doesn't need full Vault policy enforcement.
      bws

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # agenix  # alternative to sops-nix; simpler surface but less flexible
      #         # blocked on: choosing one secrets management path; revisit if
      #         # sops-nix proves cumbersome
    ];

  };
}
