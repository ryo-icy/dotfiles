{ pkgs, ... }:

let
  hister = import ./pkgs/hister.nix { inherit pkgs; };
in
{
  # hister listen にはデタッチ/デーモンモードがなく、フォアグラウンド常駐前提のため
  # systemd --user サービスとして包んでバックグラウンド常駐・自動再起動させる。
  systemd.user.services.hister = {
    Unit = {
      Description = "Hister personal search engine server";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${hister}/bin/hister listen";
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
