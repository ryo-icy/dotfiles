{ ... }: {
  # Generates ~/.ssh/config from the matchBlocks below.
  # Public keys are placed at ~/.ssh/imported_keys/ by scripts/export-ssh-keys.sh.
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "github.com" = {
        hostname     = "github.com";
        user         = "git";
        identityFile = "~/.ssh/imported_keys/github.com.pub";
      };

      "sv01" = {
        hostname     = "10.0.0.101";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv02" = {
        hostname     = "10.0.0.102";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv03" = {
        hostname     = "10.0.0.103";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv04" = {
        hostname     = "10.0.0.104";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv05" = {
        hostname     = "10.0.0.105";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-cp01" = {
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-cp02" = {
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-wk01" = {
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      # This host has no IdentityFile — authentication is done another way
      "prd-k8s-wk02" = {
        user            = "cloudinit";
        identityAgent   = "none";
        identitiesOnly  = true;
      };

      "prd-k8s-wk02.local prd-k8s-wk02.rouzinkai.local" = {
        hostname     = "prd-k8s-wk02.rouzinkai.local";
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-tailscale-01" = {
        hostname     = "10.0.0.232";
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-tailscale-02" = {
        hostname     = "10.0.0.233";
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };
    };
  };
}
