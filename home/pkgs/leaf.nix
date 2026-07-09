{ pkgs }:

let
  pname = "leaf";
  # renovate: datasource=github-releases depName=RivoLink/leaf
  version = "1.26.0";

  src = pkgs.fetchurl {
    url = "https://github.com/RivoLink/leaf/releases/download/${version}/leaf-linux-x86_64";
    hash = "sha256-Bo0AtwVMZOkhi1VTg15ZjWhf0PcZwriryxCUHtbnpgM=";
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
    install -m755 $src $out/bin/leaf
    runHook postInstall
  '';

  meta = {
    description = "Terminal Markdown previewer with a GUI-like experience";
    homepage = "https://github.com/RivoLink/leaf";
    license = pkgs.lib.licenses.mit;
    mainProgram = "leaf";
  };
}
