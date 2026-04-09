{ pkgs }:

let
  pname = "openclaw";
  # renovate: datasource=npm depName=openclaw
  version = "2026.4.9";

  # 1. ビルド済み成果物を含む NPM tarball
  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/openclaw/-/openclaw-${version}.tgz";
    hash = "sha512-w3DMKeVv7BnKmcQvq2Xu+X51HMv02L00YBX4uRDSuAEIgP3Ehm7JlKG9KTbfhAFu93143MqZNqI75/eXjkRO6Q==";
  };

  # 2. 依存関係解決のためのロックファイル (GitHub から取得)
  pnpm-lock = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/openclaw/openclaw/v${version}/pnpm-lock.yaml";
    hash = "sha256-2NxCyjAg8GqYH9K6GkIi7MdJe3zbb6mrmWv/szq44f0=";
  };

  # ロックファイルを適用したソースを作成
  patchedSrc = pkgs.runCommand "openclaw-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${src} -C $out --strip-components=1
    cp ${pnpm-lock} $out/pnpm-lock.yaml
  '';

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit pname version;
    src = patchedSrc;
    fetcherVersion = 2;
    hash = "sha256-QwsJ2WN8XL/6XOGDehdiHEGDg/NADpdNDs+9ty5G/60=";
  };

in
pkgs.stdenv.mkDerivation {
  inherit pname version pnpmDeps;
  src = patchedSrc;

  nativeBuildInputs = [
    pkgs.nodejs_24
    pkgs.pnpm
    pkgs.pnpmConfigHook
    pkgs.makeWrapper
  ];

  # すでにビルド済みなので何もしない
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/openclaw $out/bin
    
    # 全体をコピー (NPM 版なので dist/ が含まれている)
    cp -r . $out/lib/openclaw/
    
    # 壊れたシンボリックリンクを掃除
    find $out/lib/openclaw/node_modules -xtype l -delete

    # ラッパーを作成
    makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/openclaw \
      --add-flags "$out/lib/openclaw/openclaw.mjs"
    runHook postInstall
  '';

  meta = {
    description = "OpenClaw: A powerful AI agent CLI";
    homepage = "https://github.com/openclaw/openclaw";
    license = pkgs.lib.licenses.mit;
    mainProgram = "openclaw";
  };
}
