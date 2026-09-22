# Plainva —— 本地优先的 Markdown vault 编辑器（Tauri v2 + pnpm/Turborepo monorepo）。
#
# 上游既不提供 flake，也不在 nixpkgs 里（截至 2026-09 nixpkgs unstable 无 plainva
# 属性，也没有相关 PR/NUR 包），所以这里按 nixpkgs 的 cargo-tauri hook 从源码打包。
#
# 打包方式要点：
#   * cargo-tauri.hook 取代 cargoBuildHook/cargoInstallHook，在 Linux 上跑
#     `cargo tauri build --bundles deb`，再把 deb 解包出的 usr/* 搬进 $out
#     （bin/ + share/applications/ + share/icons/）。
#   * 前端由 tauri 的 beforeBuildCommand（`pnpm build` = tsc + vite build）构建，
#     pnpm 依赖走 fetchPnpmDeps，因此构建期间完全离线。
#   * 关掉 bundle.createUpdaterArtifacts：生成 updater 产物需要上游的
#     签名私钥，Nix 构建里没有；应用内的 updater 插件配置保持不变。
{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cargo-tauri,
  pkg-config,
  nodejs_22,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  glib-networking,
  libayatana-appindicator,
  yq-go,
  desktop-file-utils,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "plainva";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "plainva";
    repo = "plainva";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6Zi1DaV0ncxzziS6j22ncLf7I5g8yxF6a7BIIEcowzs=";
  };

  # Tauri 应用体在 monorepo 的子目录里，cargo 与 tauri 都从那里跑。
  cargoRoot = "apps/desktop/src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${finalAttrs.src}/apps/desktop/src-tauri/Cargo.lock";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-7GGmmdFynWXrRGGri8KmJetEJ9vtY8Mmw2d7SP64O0U=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook

    # 前端构建链（tauri 的 beforeBuildCommand 会调 pnpm build）。
    nodejs_22
    pnpm_10
    pnpmConfigHook

    pkg-config
    yq-go # postPatch 里改 tauri.conf.json
    desktop-file-utils # postInstall 里改 .desktop
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook3 ];

  buildInputs = [
    webkitgtk_4_1
    glib-networking # Tauri 的网络栈（WebKit 的 TLS/代理后端）
    libayatana-appindicator # tauri 的 tray-icon feature 会拉 libappindicator-sys
  ];

  env = {
    # pnpm 10 在非交互环境下的确认提示（例如清理 node_modules）会挂住构建。
    CI = "true";
    # 上游 package.json 写的是 pnpm@10.0.0；别让 pnpm 在离线构建里去下载它。
    pnpm_config_manage_package_manager_versions = "false";
  };

  postPatch = ''
    # 不生成 updater 产物：那需要 TAURI_SIGNING_PRIVATE_KEY，Nix 构建里没有。
    yq -iPo=json '.bundle.createUpdaterArtifacts = false' apps/desktop/src-tauri/tauri.conf.json
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    # libappindicator-sys 用 dlopen 打开硬编码的 soname，nix store 里找不到，
    # 换成绝对路径（nixpkgs 对 tauri 包的通行做法）。
    substituteInPlace "$cargoDepsCopy"/libappindicator-sys-*/src/lib.rs \
      --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
  '';

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    desktop-file-edit \
      --set-key="Comment" --set-value="Open-source, local-first editor for plain Markdown vaults" \
      "$out/share/applications/"*.desktop
  '';

  # 上游的测试是 vitest/playwright 那一套（见 package.json），不在这里跑。
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source, local-first editor for plain Markdown vaults";
    homepage = "https://plainva.com/";
    changelog = "https://github.com/plainva/plainva/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "plainva-desktop";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
