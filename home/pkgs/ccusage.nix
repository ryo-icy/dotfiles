{ pkgs }:

let
  pname = "ccusage";
  # renovate: datasource=github-releases depName=ryoppippi/ccusage
  version = "18.0.10";

  src = pkgs.fetchFromGitHub {
    owner = "ryoppippi";
    repo = "ccusage";
    rev = "v${version}";
    hash = "sha256-6KmSj2wgnkwJNnKaTmscbY+7fy2l6JHci3x3m/CV/Qg=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 2;
    hash = "sha256-6RNmV4fkUCs6mVdQ5Wv2wo8hqvI0BM/T87Kb96CmeF4=";
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
    # pnpm を使用して該当パッケージのみをビルド (モノレポ構成に対応)
    pnpm run --filter ccusage build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/ccusage $out/bin
    
    # 実行に必要なファイルをコピー
    cp -r apps/ccusage/dist apps/ccusage/node_modules apps/ccusage/package.json $out/lib/ccusage/
    
    # 壊れたシンボリックリンクを削除
    find $out/lib/ccusage/node_modules -xtype l -delete

    # ラッパーを作成
    makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/ccusage \
      --add-flags "$out/lib/ccusage/dist/index.js"
    runHook postInstall
  '';

  meta = {
    description = "Claude API usage tracker";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = pkgs.lib.licenses.mit;
    mainProgram = "ccusage";
  };
}
