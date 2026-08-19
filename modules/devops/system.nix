# modules/devops/system.nix

{ ... }:

{
  imports = [
    ../profile/options.nix
    ./options.nix
    ./containers.nix
    ./kubernetes.nix
    ./dbmss.nix
    ./iac.nix
    ./secrets.nix
    ./cloud.nix
    ./observability.nix
    ./networking.nix
    ./cicd.nix

    #./n8n-contained.nix
  ];
}
