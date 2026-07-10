{ pkgs }:

let
  pname = "hister";
  # renovate: datasource=github-releases depName=asciimoo/hister
  version = "0.16.0";

  src = pkgs.fetchurl {
    url = "https://github.com/asciimoo/hister/releases/download/v${version}/hister_${version}_linux_amd64";
    hash = "sha256-d6hAVpcQzYJFZ21aVcDCEL4AsyljA2L89R/mddwIZAY=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  # バイナリ単体の配布物なので展開不要
  dontUnpack = true;

  # プリビルド済みバイナリなのでビルド不要
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 $src $out/bin/hister
    runHook postInstall
  '';

  meta = {
    description = "Privacy-focused personal search engine that indexes browsing history locally";
    homepage = "https://github.com/asciimoo/hister";
    license = pkgs.lib.licenses.agpl3Plus;
    mainProgram = "hister";
  };
}
