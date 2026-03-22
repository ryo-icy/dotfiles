{ pkgs }:

# ccusage は依存関係なし・ビルド済みの npm パッケージのため
# buildNpmPackage を使わず fetchurl + makeWrapper で直接インストールする
pkgs.stdenv.mkDerivation rec {
  pname = "ccusage";
  version = "18.0.10";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${version}.tgz";
    # npm の integrity フィールドをそのまま利用
    hash = "sha512-bVNqaBFLo3lnSV6afiV/wtLselkGQLV4iXltcTRJwoqbDnnutw6ZNliF1CYwpF/7M0xsmXZnExR0CxdDSdT9xg==";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/ccusage
    cp -r . $out/lib/node_modules/ccusage/
    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/ccusage \
      --add-flags "$out/lib/node_modules/ccusage/dist/index.js"
    runHook postInstall
  '';
}
