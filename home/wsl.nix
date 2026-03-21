{ lib, ... }: {
  # Route ssh and ssh-add through Windows binaries so they can access
  # the Windows OpenSSH agent (which 1Password hooks into).
  programs.zsh.shellAliases = {
    ssh     = "ssh.exe";
    ssh-add = "ssh-add.exe";
  };

  # Bridge the 1Password SSH agent (Windows named pipe) to a Unix socket
  # so that Linux-native tools can also use it via SSH_AUTH_SOCK.
  # Requires: socat (in packages.nix) and ~/.local/bin/npiperelay.exe (installed by bootstrap.sh).
  home.sessionVariables.SSH_AUTH_SOCK = "/tmp/ssh-agent-1p.sock";

  programs.zsh.initContent = lib.mkAfter ''
    _1P_SOCK="/tmp/ssh-agent-1p.sock"
    _RELAY="$HOME/.local/bin/npiperelay.exe"
    if [[ ! -S "$_1P_SOCK" ]] && [[ -f "$_RELAY" ]]; then
      rm -f "$_1P_SOCK"
      (setsid socat \
        UNIX-LISTEN:"$_1P_SOCK",fork \
        EXEC:"$_RELAY -ei -s //./pipe/openssh-ssh-agent",nofork \
        &>/dev/null &)
    fi
    unset _1P_SOCK _RELAY
  '';

  # Ensure ~/.local/bin (npiperelay.exe, claude CLI, gemini CLI) are on PATH
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
