# vsc-dots

VSCodium 的 dotfiles：配置 + 扩展清单，由 nix 声明式管理。组织方式参考
`config/nvim-dots`（那份是 LazyVim 配置，通过符号链接挂到 `~/.config/nvim`）。

## 结构

```
extensions.nix       扩展清单：open-vsx 坐标 + 固定版本 + 哈希，nix 构建成扩展目录
with-extensions.nix   把扩展绑到自建的 vscodium-electron 上（--extensions-dir）
User/settings.json    用户设置，链接到 ~/.config/VSCodium/User/settings.json
User/keybindings.json 快捷键，链接到 ~/.config/VSCodium/User/keybindings.json
```

## 配置

`modules/files.nix` 用 `config.lib.file.mkOutOfStoreSymlink` 把上面两个 JSON
链接进 `~/.config/VSCodium/User/`。因为是"链到仓库里的真实文件"而不是
复制进 store，所以在编辑器 UI 里改设置会直接写回本目录，可以照常 git diff。

链接的是单个文件而不是整个 `User/` 目录：那个目录里还有 `globalStorage/`、
`workspaceStorage/`、`History/` 等运行时数据，不该进仓库。

## 扩展

扩展从 open-vsx 取，每个都固定版本与哈希，nix 构建后由
`with-extensions.nix` 通过 `--extensions-dir` 注入。代价是扩展目录只读
（在 store 里），UI 里装不了、更新不了扩展。

加扩展：往 `extensions.nix` 的列表里加一条。
升级扩展：

```sh
curl -s https://open-vsx.org/api/<ns>/<name>/latest | jq '{version, download: .files.download}'
nix store prefetch-file --json --hash-type sha256 '<上面输出的 download>'
# 把 version 与 hash 填回 extensions.nix
```

VSCodium 与 electron 本体由 `pkgs/vscodium-electron.nix` 打包（官方 RPM +
nixpkgs 的 electron）。升级 VSCodium：改那个文件里的 `version`、`url` 里的
版本号与 `hash`（hash 用官方的 `sha256sums_x86_64`，见 AUR 的
vscodium-electron-bin `.SRCINFO`）。

## 历史遗留

`~/.vscode-oss/extensions/` 里还留着以前手动装的 8 个扩展（AUR 版 VSCodium
装的）。切到 `--extensions-dir` 后它们不会被加载，可以删掉：
`rm -rf ~/.vscode-oss/extensions`。
