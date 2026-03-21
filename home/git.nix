{ ... }: {
  programs.git = {
    enable = true;
    userName  = "ryo-icy";
    userEmail = "74962200+ryo-icy@users.noreply.github.com";
    extraConfig = {
      # Use Windows SSH binary so git can access the 1Password SSH agent
      core.sshCommand = "ssh.exe";
      init.defaultBranch = "main";
    };
  };
}
