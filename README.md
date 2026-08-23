# Home Manager 配置（flake）

在 LFS 上以独立（standalone）方式使用 Home Manager，不依赖 NixOS。
跟随 **nixpkgs `nixos-unstable` / home-manager `master`**（unstable，与 NixOS 上习惯一致）。

## 前置要求

- Nix ≥ 2.4，且 `nix-command`、`flakes` 已启用（见 `~/.config/nix/nix.conf`）：

  ```
  experimental-features = nix-command flakes
  ```

## 日常命令

| 命令 | 作用 |
| --- | --- |
| `nix run ~/nix -- switch -b hm-backup --flake ~/nix` | 构建并应用配置（alias: `hm-switch`；`-b hm-backup` 会把将被覆盖的旧文件备份为 `*.hm-backup`） |
| `nix flake update ~/nix` | 更新依赖锁定文件 `flake.lock`（alias: `hm-update`） |
| `nix fmt` | 用 nixfmt 格式化仓库内所有 Nix 文件 |
| `nix run ~/nix -- news` | 查看 Home Manager 最近的变更公告 |

## 目录结构

| 文件 | 作用 |
| --- | --- |
| `flake.nix` | 固定 nixpkgs / home-manager 输入，导出 `homeConfigurations.Qaaxaap` |
| `home.nix` | 入口：用户名、home 目录、`stateVersion` |
| `modules/defaults.nix` | 环境变量、常备小工具、任意 home 文件 |
| `modules/shell.nix` | bash 配置（历史、别名） |
| `modules/cli.nix` | git / direnv / fzf 与常用 CLI 工具 |

新增模块只需在 `flake.nix` 的 `modules = [ ... ]` 列表里加一行。

## 切到稳定版

把 `flake.nix` 中两个 input 的 url 改为（以 26.05 为例）：

```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
home-manager.url = "github:nix-community/home-manager/release-26.05";
```

然后 `nix flake update ~/nix && nix run ~/nix -- switch --flake ~/nix`。

## 注意事项

- `home.stateVersion` 只在跨版本升级且阅读过 release notes 后修改，不要随便动。
- 首次 switch 后 `~/.bashrc` 等文件由 Home Manager 接管（原文件因 `-b hm-backup` 被备份为 `~/.bashrc.hm-backup`）。
- 登录 shell 仍是系统的 `/bin/bash`；若想用 Home Manager 的 bash 作为登录 shell，需要 root 把 `~/.nix-profile/bin/bash` 加入 `/etc/shells` 再 `chsh`。
