{ ... }: {
  # Generates ~/.ssh/config from the matchBlocks below.
  # Public keys are placed at ~/.ssh/imported_keys/ by scripts/export-ssh-keys.sh.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        Hostname     = "github.com";
        User         = "git";
        IdentityFile = "~/.ssh/imported_keys/github.com.pub";
      };

      "sv01" = {
        Hostname     = "sv01.rouzinkai.local";
        User         = "rouzin-user";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv02" = {
        Hostname     = "sv02.rouzinkai.local";
        User         = "rouzin-user";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "sv03" = {
        Hostname     = "sv03.rouzinkai.local";
        User         = "rouzin-user";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-sv01" = {
        Hostname     = "dev-sv01.rouzinkai.local";
        User         = "rouzin-user";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-sv02" = {
        Hostname     = "dev-sv02.rouzinkai.local";
        User         = "rouzin-user";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-cp01" = {
        Hostname     = "prd-k8s-cp01.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-cp02" = {
        Hostname     = "prd-k8s-cp02.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-wk01" = {
        Hostname     = "prd-k8s-wk01.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-k8s-wk02" = {
        Hostname     = "prd-k8s-wk02.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-k8s-cp01" = {
        Hostname     = "dev-k8s-cp01.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-k8s-cp02" = {
        Hostname     = "dev-k8s-cp02.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-k8s-wk01" = {
        Hostname     = "dev-k8s-wk01.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-k8s-wk02" = {
        Hostname     = "dev-k8s-wk02.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "prd-tailscale-01" = {
        Hostname     = "prd-tailscale-01.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };

      "dev-tailscale-01" = {
        Hostname     = "dev-tailscale-01.rouzinkai.local";
        User         = "cloudinit";
        IdentityFile = "~/.ssh/imported_keys/rouzinkai.pub";
      };
    };
  };
}
