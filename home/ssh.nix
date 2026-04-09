{ ... }: {
  # Generates ~/.ssh/config from the matchBlocks below.
  # Public keys are placed at ~/.ssh/imported_keys/ by scripts/export-ssh-keys.sh.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "github.com" = {
        hostname     = "github.com";
        user         = "git";
        identityFile = "~/.ssh/imported_keys/github.com.pub";
      };

      "sv01 sv01.rouzinkai.local" = {
        hostname     = "sv01.rouzinkai.local";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv02 sv02.rouzinkai.local" = {
        hostname     = "sv02.rouzinkai.local";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv03 sv03.rouzinkai.local" = {
        hostname     = "sv03.rouzinkai.local";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv04 sv04.rouzinkai.local" = {
        hostname     = "sv04.rouzinkai.local";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv05 sv05.rouzinkai.local" = {
        hostname     = "sv05.rouzinkai.local";
        user         = "rouzin-user";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-cp01 prd-k8s-cp01.rouzinkai.local" = {
        hostname     = "prd-k8s-cp01.rouzinkai.local";
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-cp02 prd-k8s-cp02.rouzinkai.local" = {
        hostname     = "prd-k8s-cp02.rouzinkai.local";
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-wk01 prd-k8s-wk01.rouzinkai.local" = {
        hostname     = "prd-k8s-wk01.rouzinkai.local";
        user         = "cloudinit";
        identityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-wk02 prd-k8s-wk02.rouzinkai.local" = {
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
