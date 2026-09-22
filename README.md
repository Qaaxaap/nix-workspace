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

个别包由专用模块安装，不走这个列表：例如 `modules/omp.nix` 引入上游 oh-my-pi 自带的 Home Manager 模块来装 `omp`。

上游没有 flake / nixpkgs 包的软件，则用仓库内的本地 derivation 打包，再在列表里 `callPackage`：目前有 [`pkgs/plainva.nix`](./pkgs/plainva.nix)（Plainva Markdown 编辑器，走 nixpkgs 的 `cargo-tauri.hook` 从源码构建）。升级时改文件里的 `version` 与 `src` / `pnpmDeps` 两个 hash。

回滚上次变更：`home-manager generations` 查看，`~/.nix-profile/bin/home-manager switch --generations <N>` 切换。

## 目录结构

| 文件 | 作用 |
| --- | --- |
| `flake.nix` | 固定 nixpkgs / home-manager 输入，导出 `homeConfigurations.Qaaxaap`、默认 app 和默认 devShell |
| `home.nix` | 入口：用户名、home 目录、`stateVersion` |
| `modules/packages.nix` | **包列表（唯一数据源：HM 安装和 devShell 都从这里取）** |
| `modules/shell.nix` | 预留：目前为空。 |
| `modules/omp.nix` | omp（[oh-my-pi](https://github.com/can1357/oh-my-pi)）编码代理：引入上游 `homeManagerModules` 并启用 |
| `pkgs/plainva.nix` | Plainva 的本地 derivation（上游无 flake；nixpkgs 也没有该包），经 `flake.nix` 的 `packages` / `overlays` 暴露 |

## 别人怎么用这个 flake

仓库里本地打包的包（目前是 `pkgs/plainva.nix`）通过 flake output 暴露出来了，可以单独复用，不必整套配置照搬：

- 直接构建／运行：

  ```bash
  nix run github:Qaaxaap/nix-workspace#plainva    # 构建并启动
  nix build github:Qaaxaap/nix-workspace#plainva  # 只要 result/bin/plainva-desktop
  ```

- 在自己的 flake 里当 overlay 用（NixOS / Home Manager 同理）：

  ```nix
  inputs.nix-workspace = {
    url = "github:Qaaxaap/nix-workspace";
    # 让两边共用同一份 nixpkgs，避免出现两套依赖
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```

  ```nix
  { nix-workspace, pkgs, ... }:
  {
    nixpkgs.overlays = [ nix-workspace.overlays.default ];
    environment.systemPackages = [ pkgs.plainva ];   # Home Manager 则用 home.packages
  }
  ```

  或者不用 overlay，直接引用 output：

  ```nix
  home.packages = [ nix-workspace.packages.${pkgs.stdenv.hostPlatform.system}.plainva ];
  ```

- 只想要那一个包、不想连带求值本仓库其它 input（`nix-workspace` 会连带求值 home-manager / nixGL / omp 这些 input）：把 [`pkgs/plainva.nix`](./pkgs/plainva.nix) 抄进自己仓库，然后 `pkgs.callPackage ./plainva.nix { }` —— 它只用 nixpkgs。

当前只声明 `x86_64-linux`（上游 Linux 端依赖 WebKitGTK ≥ 2.40）。

## 切到稳定版

把 `flake.nix` 中两个 input 的 url 改为（以 26.05 为例）：

```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
home-manager.url = "github:nix-community/home-manager/release-26.05";
```
