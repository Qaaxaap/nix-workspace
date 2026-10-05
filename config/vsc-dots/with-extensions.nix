# 把 extensions.nix 里的扩展绑到自建的 vscodium-electron 上。
#
# 做法同 nixpkgs 的 vscode-with-extensions：
#   * buildEnv 把各扩展（$out/share/vscode/extensions/<id>）合并成一个目录，
#     并写入 extensions.json（VS Code 用它识别内置扩展）；
#   * 用 makeWrapper 包一层，给编辑器加 --extensions-dir 指向该目录。
#
# 结果是扩展目录只读（在 store 里），UI 里不能安装/更新扩展；
# 需要什么扩展就往 extensions.nix 里加。
{ pkgs, vscodium-electron, extensions }:
let
  extensionJsonFile = pkgs.writeTextFile {
    name = "vscodium-extensions-json";
    destination = "/share/vscode/extensions/extensions.json";
    text = pkgs.vscode-utils.toExtensionJson extensions;
  };

  combinedExtensions = pkgs.buildEnv {
    name = "vscodium-electron-extensions";
    paths = extensions ++ [ extensionJsonFile ];
  };
in
pkgs.runCommand "vscodium-electron-with-extensions-${vscodium-electron.version}" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  passthru = {
    inherit extensions;
    inherit (vscodium-electron) version;
  };
  meta = vscodium-electron.meta // {
    description = "VSCodium (nixpkgs Electron) with the extension set from vsc-dots";
    mainProgram = "vscodium-electron";
  };
} ''
  mkdir -p $out/bin $out/share/applications $out/share/pixmaps

  makeWrapper ${vscodium-electron}/bin/vscodium-electron $out/bin/vscodium-electron \
    --add-flags "--extensions-dir ${combinedExtensions}/share/vscode/extensions"

  for f in ${vscodium-electron}/share/applications/*.desktop; do
    ln -s "$f" $out/share/applications/
  done

  if [ -d ${vscodium-electron}/share/pixmaps ]; then
    for f in ${vscodium-electron}/share/pixmaps/*; do
      ln -s "$f" $out/share/pixmaps/
    done
  fi
''
