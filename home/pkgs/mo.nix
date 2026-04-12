{ pkgs }:

let
  pname = "mo";
  # renovate: datasource=github-releases depName=k1LoW/mo
  version = "1.1.0";

  src = pkgs.fetchurl {
    url = "https://github.com/k1LoW/mo/releases/download/v${version}/mo_v${version}_linux_amd64.tar.gz";
    hash = "sha256-JD46j6CN/sadi8uCYKT34U07aNG+8B4Y2Mo3ASFVXEA=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  # tarball がディレクトリを持たないのでそのまま展開
  sourceRoot = ".";

  # Go バイナリは単体なので別途ビルド不要
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 mo $out/bin/mo
    runHook postInstall
  '';

  meta = {
    description = "Markdown viewer that opens .md files in a browser";
    homepage = "https://github.com/k1LoW/mo";
    license = pkgs.lib.licenses.mit;
    mainProgram = "mo";
  };
}
