# Plainva（二进制版）—— 直接用上游 release 页的 .deb 装，不编译 Rust 与前端。
#
# 与 pkgs/plainva.nix（源码版）的关系：两者装出来的都是 bin/plainva-desktop，
# 功能相同，区别只在代价。源码版每次 nixpkgs 或工具链变动都要重跑一遍
# cargo + pnpm 构建（几十分钟），这个版本只解包、改 RUNPATH、套 wrapper（几秒），
# 因此 Home Manager 默认用这个；源码版留给需要本地补丁或在 nixpkgs 里复用的人。
#
# 上游只发 x86_64 Linux 的 deb / rpm / AppImage，deb 最小也最好解，所以取 deb。
#
# 打包方式要点：
#   * stdenvNoCC + dpkg-deb -x 解出 usr/*，保持上游的 bin/ 与 share/ 布局。
#   * 二进制链接系统 WebKitGTK 与 GTK，autoPatchelfHook 把 RUNPATH 指到 nix store。
#   * libayatana-appindicator 不在 DT_NEEDED 里（libappindicator-sys 用 dlopen
#     打开硬编码 soname），所以走 runtimeDependencies 进 RUNPATH——动态链接器
#     创建托盘图标时会往那里找。
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  gdk-pixbuf,
  cairo,
  glib,
  glib-networking,
  dbus,
  libsoup_3,
  webkitgtk_4_1,
  libayatana-appindicator,
  # 升级时这两个一起改：
  #   nix store prefetch-file --json --hash-type sha256 \
  #     https://github.com/plainva/plainva/releases/download/vX.Y.Z/Plainva_X.Y.Z_amd64.deb
  version ? "0.8.4",
  hash ? "sha256-83EIWX8ptKeuKEu77yCvLY59p6r9HpPPvZb/73jIxDw=",
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "plainva-bin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/plainva/plainva/releases/download/v${finalAttrs.version}/Plainva_${finalAttrs.version}_amd64.deb";
    inherit hash;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    gdk-pixbuf
    cairo
    glib
    glib-networking # WebKit 网络栈的 TLS/代理后端
    dbus
    libsoup_3
    webkitgtk_4_1
  ];

  # 托盘图标用 dlopen 加载，不会出现在 DT_NEEDED 里。
  runtimeDependencies = [ libayatana-appindicator ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x ${finalAttrs.src} .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out/
    runHook postInstall
  '';

  meta = {
    description = "Open-source, local-first editor for plain Markdown vaults (prebuilt binary)";
    homepage = "https://plainva.com/";
    changelog = "https://github.com/plainva/plainva/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "plainva-desktop";
    # release 页只有 amd64 的 deb。
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
