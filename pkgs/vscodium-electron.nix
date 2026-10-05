# vscodium-electron —— 用 nixpkgs 的 electron 运行 VSCodium。
#
# 与 nixpkgs 里的 `vscodium` 的区别：那个用的是官方 tar.gz 中自带的
# electron（多占一份 electron，约 200 MiB，且版本停在 1.126）。这里照搬
# AUR 的 vscodium-electron-bin 的思路：
#   https://aur.archlinux.org/packages/vscodium-electron-bin
# 下载官方 RPM，只取其中的 resources/app，交给 nixpkgs 的 electron_42 运行，
# 于是 electron 与 store 里其它 electron 应用共享。
#
# VSCodium 1.135.06055 的 RPM 内含 electron 42.8.1，本仓库 nixpkgs 的
# electron_42 是 42.11.10。Electron 只在主版本之间破坏 ABI，所以能换。
#
# 配置目录沿用 AUR 包的 `vscodium-electron`（~/.config/vscodium-electron），
# 与 pacman 装的 vscodium-electron-bin 可以直接对换。
{
  lib,
  stdenv,
  fetchurl,
  bash,
  libarchive,
  electron_42,
  ripgrep,
  libx11,
  libxkbfile,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vscodium-electron";
  version = "1.135.06055";

  src = fetchurl {
    url = "https://github.com/VSCodium/vscodium/releases/download/${finalAttrs.version}/codium-${finalAttrs.version}-el8.x86_64.rpm";
    hash = "sha256-zK4l7LBP5tPy+U1XjXzimQSBrjZQYz0FwIGS+1/b6hI=";
  };

  nativeBuildInputs = [
    libarchive # bsdtar 能直接解 RPM 的 payload，不必 rpm2cpio | cpio
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libx11
    libxkbfile
  ];

  # app 里有些 dlopen 才用到的库（libsecret、libwebkit2gtk 等），patchelf
  # 找不到不代表跑不起来：libsecret 与 webkitgtk 系统里已有，动态链接器
  # 会走默认搜索路径；而且把 nixpkgs 的 webkitgtk 塞进 RPATH 会把整个
  # webkit/gstreamer 栈拖进 closure（实测 1.8 GiB）。
  autoPatchelfIgnoreMissingDeps = true;

  desktopItems = [
    (makeDesktopItem {
      name = "vscodium-electron";
      desktopName = "VSCodium";
      genericName = "Text Editor";
      comment = "Free/Libre Open Source Software Binaries of Visual Studio Code";
      exec = "vscodium-electron %F";
      icon = "vscodium-electron";
      categories = [ "Development" "TextEditor" ];
      startupWMClass = "vscodium-electron";
      mimeTypes = [ "text/plain" "inode/directory" ];
      actions = {
        new-empty-window = {
          name = "New Empty Window";
          exec = "vscodium-electron --new-window %F";
        };
      };
    })
    (makeDesktopItem {
      name = "vscodium-electron-url-handler";
      desktopName = "VSCodium - URL Handler";
      exec = "vscodium-electron --open-url %U";
      icon = "vscodium-electron";
      categories = [ "Utility" "TextEditor" "Development" ];
      startupWMClass = "vscodium-electron";
      mimeTypes = [ "x-scheme-handler/vscodium" "x-scheme-handler/codium" ];
      noDisplay = true;
    })
  ];

  # RPM 的 payload 路径就是 ./usr/...，直接解到构建目录
  unpackPhase = ''
    runHook preUnpack
    bsdtar --no-same-owner -xf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    appdir=$out/lib/vscodium-electron
    mkdir -p "$appdir" "$out/bin"
    cp -a usr/share/codium/resources/app/. "$appdir/"

    # 包内自带的 ripgrep 覆盖各平台，换成 nixpkgs 的 rg，只留 linux-x64
    rgdir="$appdir/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin"
    if [ -d "$rgdir" ]; then
      rm -rf "$rgdir"
      mkdir -p "$rgdir/linux-x64"
      ln -s ${ripgrep}/bin/rg "$rgdir/linux-x64/rg"
    fi

    # RPM 带的图标（usr/share/pixmaps/vscodium.png）用 vscodium-electron 这个名字
    install -Dm644 usr/share/pixmaps/vscodium.png "$out/share/pixmaps/vscodium-electron.png"

    # 补全
    install -Dm644 usr/share/codium/resources/completions/bash/codium \
      "$out/share/bash-completion/completions/vscodium-electron"
    install -Dm644 usr/share/codium/resources/completions/zsh/_codium \
      "$out/share/zsh/site-functions/_vscodium-electron"

    install -Dm644 "$appdir/LICENSE.txt" "$out/share/licenses/vscodium-electron/LICENSE"

    # 启动器：把 AUR 的 vscodium-electron.js 放到 app 目录里，
    # electron 以 ELECTRON_RUN_AS_NODE 跑 out/cli.js，再由它拉起这个 js。
    cat > "$appdir/vscodium-electron.js" <<'EOF'
    // 取自 AUR 的 vscodium-electron-bin（vscodium-electron.js）
    import { app } from "electron/main";
    import * as path from "node:path";
    import * as fs from "node:fs";

    const name = "vscodium-electron";

    // 改掉 /proc/self/comm 里的名字，进程列表和窗口 class 都用它
    const fd = fs.openSync("/proc/self/comm", fs.constants.O_WRONLY);
    fs.writeSync(fd, name);
    fs.closeSync(fd);

    // 去掉 electron 自己加在前面的参数
    process.argv.splice(
      0,
      process.argv.findIndex((arg) => arg.endsWith("/vscodium-electron.js")),
    );

    const appPath = import.meta.dirname;
    const packageJson = JSON.parse(fs.readFileSync(new URL("./package.json", import.meta.url)));
    app.setAppPath(appPath);
    app.setDesktopName(name + ".desktop");
    app.setName(name);
    app.setPath("userCache", path.join(app.getPath("cache"), name));
    app.setPath("userData", path.join(app.getPath("appData"), name));
    app.setVersion(packageJson.version);

    await import(appPath + "/out/main.js");
    EOF

    # 启动脚本，对应 AUR 的 vscodium-electron.sh
    cat > "$out/bin/vscodium-electron" <<'EOF'
    #!@bash@
    set -o pipefail

    _APPDIR="@out@/lib/vscodium-electron"

    export PATH="$_APPDIR:$PATH"
    export ELECTRON_IS_DEV=0
    export ELECTRON_FORCE_IS_PACKAGED=true
    export ELECTRON_DISABLE_SECURITY_WARNINGS=true
    export ELECTRON_OVERRIDE_DIST_PATH="@electrondist@"
    export NODE_ENV=production
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"

    # 用户附加的 electron flags，与 AUR 包同名
    _FLAGS_FILE="$XDG_CONFIG_HOME/vscodium-electron-flags.conf"
    declare -a flags=()
    if [[ -f "$_FLAGS_FILE" ]]; then
      mapfile -t lines < "$_FLAGS_FILE"
      for line in "''${lines[@]}"; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        flags+=("$line")
      done
    fi

    cd "$_APPDIR" || exit 1

    if [ "''${XDG_SESSION_TYPE:-}" = "wayland" ]; then
      unset DISPLAY
      exec @electron@ "$_APPDIR/out/cli.js" \
        --enable-features=UseOzonePlatform \
        --ozone-platform=wayland \
        "$_APPDIR/vscodium-electron.js" "''${flags[@]}" "$@"
    else
      ELECTRON_RUN_AS_NODE=1 exec @electron@ "$_APPDIR/out/cli.js" \
        "$_APPDIR/vscodium-electron.js" "''${flags[@]}" "$@"
    fi
    EOF
    chmod 755 "$out/bin/vscodium-electron"

    substituteInPlace "$out/bin/vscodium-electron" \
      --subst-var-by bash "${bash}/bin/bash" \
      --subst-var-by out "$out" \
      --subst-var-by electron "${electron_42}/bin/electron" \
      --subst-var-by electrondist "${electron_42.dist}"

    runHook postInstall
  '';

  meta = {
    description = "VSCodium running on the nixpkgs Electron (no bundled Electron)";
    longDescription = ''
      VSCodium built from the official RPM, with the bundled Electron stripped out
      and replaced by nixpkgs' electron_42 so that Electron is shared in the store.
      The approach is the same as the AUR package vscodium-electron-bin.
    '';
    homepage = "https://vscodium.com/";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      binaryBytecode
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "vscodium-electron";
  };
})
