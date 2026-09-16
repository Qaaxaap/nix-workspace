{ omp, ... }:

{
  # omp（oh-my-pi）编码代理：https://github.com/can1357/oh-my-pi
  #
  # 上游 flake 自带 Home Manager 模块，这里只做两件事：引入它、打开开关。
  # 刻意不写 programs.omp.settings —— 该选项留空时 HM 不会碰
  # ~/.omp/agent/config.yml，运行时配置继续由 omp 自己维护（与 files.nix
  # 一样，不让 HM 接管程序自身的配置文件）。
  imports = [ omp.homeManagerModules.default ];

  programs.omp.enable = true;
}
