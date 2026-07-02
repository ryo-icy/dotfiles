{ pkgs }:

let
  pname = "herdr";
  # renovate: datasource=github-releases depName=ogulcancelik/herdr
  version = "0.7.1";

  src = pkgs.fetchurl {
    url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/herdr-linux-x86_64";
    hash = "sha256-uWWsr/wsIvVLbmxkr3z46Yo/SsJiJjCgWZxnpLnYplQ=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  # バイナリ単体の配布物なので展開不要
  dontUnpack = true;

  # Rust バイナリは単体なので別途ビルド不要
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://github.com/ogulcancelik/herdr";
    license = pkgs.lib.licenses.agpl3Plus;
    mainProgram = "herdr";
  };
}
