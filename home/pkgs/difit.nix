{ pkgs }:

let
  pname = "difit";
  # renovate: datasource=github-releases depName=yoshiko-pg/difit
  version = "4.0.3";

  src = pkgs.fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${version}";
    hash = "sha256-FXxHxujI1hM0LmWm+y9dFiQdtU9GmQmwrbDsegGlSwk=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 2;
    hash = "sha256-oy0IXrAkdCsZT6ZRSknoV9OcUdLV6wpd491/YqWoleg=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src pnpmDeps;

  nativeBuildInputs = [
    pkgs.nodejs_24
    pkgs.pnpm
    pkgs.pnpmConfigHook
    pkgs.makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    # Node.js 24 環境でビルドを実行
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/difit $out/bin
    
    # 実行に必要なファイルをコピー
    # package.json, dist, node_modules, packages が必要
    cp -r dist node_modules package.json packages $out/lib/difit/
    
    # 壊れたシンボリックリンクを削除
    find $out/lib/difit/node_modules -xtype l -delete

    # ラッパーを作成
    makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/difit \
      --add-flags "$out/lib/difit/dist/cli/index.js"
    runHook postInstall
  '';

  meta = {
    description = "A lightweight command-line tool to display Git diffs in a GitHub-like view";
    homepage = "https://github.com/yoshiko-pg/difit";
    license = pkgs.lib.licenses.mit;
    mainProgram = "difit";
  };
}
