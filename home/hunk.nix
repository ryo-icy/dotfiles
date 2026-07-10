{ pkgs, ... }: {
  # hunk: レビュー重視のdiffビューア。コードレビューの既定設定を固定する。
  home.packages = [ (import ./pkgs/hunk.nix { inherit pkgs; }) ];

  xdg.configFile."hunk/config.toml".text = ''
    mode = "split"
    wrap_lines = true
  '';
}
