# Home Manager(flake) 构建的个人工作区

旨在以可复现/一切皆配置的方式打造一个个人工作区，虽然只是自用项目，但也有一定的通用性，可以作为 Home-Manager/Nix/Linux 入门参考与快速开始。

在这里会有意无意地使用到各种点文件的管理方式、软件包的管理方式、flake 的使用等等，并且不会太过复杂，阅读并理解可以检验 Nix 的学习成果。

包的挑选是按照我的个人喜好，但是会尽量在这里只放置泛用的包。

> 跟随 **nixpkgs `nixos-unstable` / home-manager `master`**。

## 前置要求

- Nix ≥ 2.4，且 `nix-command`、`flakes` 已启用（见 `~/.config/nix/nix.conf`：

  ```
  experimental-features = nix-command flakes
  ```

## Nix 日常命令

| 命令 | 作用 |
| --- | --- |
| `nix run ~/nix -- switch -b hm-backup --flake ~/nix` | 构建并应用配置 |
| `nix flake update ~/nix` | 更新依赖锁定文件 `flake.lock` |
| `nix fmt` | 格式化仓库内所有 Nix 文件 |
| `nix run ~/nix -- news` | 查看 Home Manager 更新公告 |
| `nix develop ~/nix` | 进入默认 devShell（与 HM 包集同源 + git/nixfmt），退出 `exit` |

事实上本配置启用了 nixos helper(nh)，方便使用且美观。

## 装包 / 卸包

编辑 [`modules/packages.nix`](./modules/packages.nix)，在 `home.packages` 列表里加/删，然后构建切换。包会出现在 `~/.nix-profile/bin`。

回滚上次变更：`home-manager generations` 查看，`~/.nix-profile/bin/home-manager switch --generations <N>` 切换。

## 目录结构

| 文件 | 作用 |
| --- | --- |
| `flake.nix` | 固定 nixpkgs / home-manager 输入，导出 `homeConfigurations.Qaaxaap`、默认 app 和默认 devShell |
| `home.nix` | 入口：用户名、home 目录、`stateVersion` |
| `modules/packages.nix` | **包列表（唯一数据源：HM 安装和 devShell 都从这里取）** |
| `modules/shell.nix` | 预留：目前为空。 |

## 切到稳定版

把 `flake.nix` 中两个 input 的 url 改为（以 26.05 为例）：

```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
home-manager.url = "github:nix-community/home-manager/release-26.05";
```
