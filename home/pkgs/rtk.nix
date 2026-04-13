{ pkgs }:

let
  pname = "rtk";
  # renovate: datasource=github-releases depName=rtk-ai/rtk
  version = "0.35.0";

  src = pkgs.fetchurl {
    url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-MMhSpvQVqKJwqqMzxhS7At/Q1gvFevOC9btEw7Yab/k=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  # tarball がディレクトリを持たないのでそのまま展開
  sourceRoot = ".";

  # Rust バイナリは単体なので別途ビルド不要
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 rtk $out/bin/rtk
    runHook postInstall
  '';

  meta = {
    description = "Reduce LLM token consumption by 60-90% on common dev commands";
    homepage = "https://github.com/rtk-ai/rtk";
    license = pkgs.lib.licenses.mit;
    mainProgram = "rtk";
  };
}
