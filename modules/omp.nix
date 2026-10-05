{ config, lib, pkgs, omp, ... }:
let
  # 用上游 release 的预编译二进制，而不是 omp flake input 里那份源码构建的包：
  # 后者一次要二十分钟（Rust 全套 + Bun bundle），上游声明的 cachix 上也没有
  # 对应产物。详见 pkgs/omp-bin.nix。比 input 里的 18.6.2 低一个小版本。
  ompPackage = pkgs.callPackage ../pkgs/omp-bin.nix { };
in
{
  imports = [ omp.homeManagerModules.default ];

  programs.omp = {
    enable = true;
    package = ompPackage;
  };

  # omp 是 Bun 的单文件可执行文件，patchelf 会把它的内嵌 entry 弄坏
  # （见 pkgs/omp-bin.nix），所以它用的是系统 interpreter，在 nix 构建沙箱里
  # 跑不起来。补全因此放到 activation（用户会话）里生成，而不是 home.file +
  # runCommand。
  home.activation.ompCompletions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.zsh/completions"
    if [ -x "${ompPackage}/bin/omp" ]; then
      $DRY_RUN_CMD ${ompPackage}/bin/omp completions zsh > "$HOME/.zsh/completions/_omp" || true
    fi
  '';
}
