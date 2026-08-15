final: prev: {
  anydesk = prev.anydesk.overrideAttrs (old: rec {
    version = "8.0.4";
    src = prev.fetchurl {
      url = "https://download.anydesk.com/linux/anydesk-${version}-amd64.tar.gz";

      # nix-prefetch-url https://download.anydesk.com/linux/anydesk-8.0.4-amd64.tar.gz
      # nix hash convert --hash-algo sha256 --to sri [hash]
      hash = "sha256-fg3sLcushu5zDvsBakHLP/FRqhvauICx86rlpK4YkW8=";
    };
  });
}
