{ pkgs }:

let
  pname = "hunk";
  # renovate: datasource=github-releases depName=modem-dev/hunk
  version = "0.17.0";

  src = pkgs.fetchurl {
    url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-linux-x64.tar.gz";
    hash = "sha256-DGJvemaHqYJjBOod9pbaXUnt+EJx7M31f//1g0KJ4OI=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  sourceRoot = "hunkdiff-linux-x64";

  # 配布物はプリビルド済みバイナリなのでビルド不要
  dontBuild = true;

  # bun --compile で生成されたバイナリは ELF 末尾に JS バンドルを追記した自己完結形式のため、
  # strip で末尾データが破損し実行時に "bun" のジェネリックヘルプにフォールバックしてしまう
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 hunk $out/bin/hunk
    runHook postInstall
  '';

  meta = {
    description = "Review-first terminal diff viewer for agentic coders";
    homepage = "https://github.com/modem-dev/hunk";
    license = pkgs.lib.licenses.mit;
    mainProgram = "hunk";
  };
}
