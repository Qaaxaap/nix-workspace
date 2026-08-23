# Home Manager（flake）—— 包管理器用法

在 LFS 上以独立（standalone）方式使用 Home Manager，**只当包管理器用**：
装包、升级、回滚，不接管任何已有配置文件（`.zshrc`、`.bashrc`、git 配置等一律不碰）。
跟随 **nixpkgs `nixos-unstable` / home-manager `master`**。

## 前置要求

- Nix ≥ 2.4，且 `nix-command`、`flakes` 已启用（见 `~/.config/nix/nix.conf`）：

  ```
  experimental-features = nix-command flakes
  ```

- PATH 无需配置：`/etc/profile.d/nix-daemon.sh` 已把 `~/.nix-profile/bin` 加进登录 shell 的 PATH。

## 日常命令

| 命令 | 作用 |
| --- | --- |
| `nix run ~/nix -- switch -b hm-backup --flake ~/nix` | 构建并应用配置（`-b hm-backup`：万一将来接管配置文件时自动备份原件） |
| `nix flake update ~/nix` | 更新依赖锁定文件 `flake.lock` |
| `nix fmt` | 格式化仓库内所有 Nix 文件 |
| `nix run ~/nix -- news` | 查看 Home Manager 更新公告 |
| `nix develop ~/nix` | 进入默认 devShell（与 HM 包集同源 + git/nixfmt），退出 `exit` |

> 可在自己的 `.zshrc` 里加两行（完全可选，HM 不会替你加）：
>
> ```zsh
> alias hm-switch='nix run ~/nix -- switch -b hm-backup --flake ~/nix'
> alias hm-update='nix flake update ~/nix'
> ```

## 装包 / 卸包

编辑 [`modules/packages.nix`](./modules/packages.nix)，在 `home.packages` 列表里加/删一行，然后 `nix run ~/nix -- switch -b hm-backup --flake ~/nix`。包只会出现在 `~/.nix-profile/bin`，不动任何点文件。

回滚上次变更：`home-manager generations` 查看，`~/.nix-profile/bin/home-manager switch --generations <N>` 切换。

## 目录结构

| 文件 | 作用 |
| --- | --- |
| `flake.nix` | 固定 nixpkgs / home-manager 输入，导出 `homeConfigurations.Qaaxaap`、默认 app 和默认 devShell |
| `home.nix` | 入口：用户名、home 目录、`stateVersion` |
| `modules/packages.nix` | **包列表（唯一数据源：HM 安装和 devShell 都从这里取）** |
| `modules/shell.nix` | 预留：目前为空。将来想托管 `~/.zshrc` 时取消注释示例 |

## 什么是"接管配置文件"？

`programs.git`、`programs.zsh`、`programs.bash` 这类模块启用后，HM 会把对应点文件
（`~/.zshrc`、`~/.gitconfig` 等）替换成指向 nix store 的符号链接，内容改由 Nix 配置生成。
本配置目前**全部未启用**；将来想托管时，原文件会因 `-b hm-backup` 自动备份为 `*.hm-backup`，
在 `modules/shell.nix` 里已有 zsh 示例。

## 切到稳定版

把 `flake.nix` 中两个 input 的 url 改为（以 26.05 为例）：

```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
home-manager.url = "github:nix-community/home-manager/release-26.05";
```

然后 `nix flake update ~/nix && nix run ~/nix -- switch -b hm-backup --flake ~/nix`。

## 注意事项

- `home.stateVersion` 只在跨版本升级且阅读过 release notes 后修改，不要随便动。
- fzf / direnv 只装了二进制；想让它们挂进 zsh，需要在你的 `.zshrc` 里自己加 hook 行。
- 登录 shell 仍是系统的 `/usr/bin/zsh`；若想用 HM 装的 zsh，需要 root 把 `~/.nix-profile/bin/zsh` 加入 `/etc/shells` 再 `chsh`。
