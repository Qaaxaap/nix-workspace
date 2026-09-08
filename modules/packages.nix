{ config, pkgs, nixGL, ... }:
let
  nixGLIntel = nixGL.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel;
  # 一个通用的"GL 包装器"：把任意 nix 程序变成免前缀的 GPU 版
  glWrap = pkg: pkgs.writeShellScriptBin (pkgs.lib.getName pkg) ''
    exec ${nixGLIntel}/bin/nixGLIntel ${pkg}/bin/${pkgs.lib.getName pkg} "$@"
  '';
in
{
  # ============================================================
  # 包管理：这里的东西装进 ~/.nix-profile。
  # 要装什么包，往下面加一行即可。
  # ============================================================
  home.packages = with pkgs; [
    # Nix 相关
    nix-output-monitor # nom build / nom develop
    nh

    # 搜索 / 文件
    ripgrep
    fd
    fzf
    logseq

    # 常用 CLI
    jq
    tree
    htop
    direnv # 需自己在 .zshrc 加: eval "$(direnv hook zsh)"
    nvchecker  s-tui  scour  opencc
    pnpm
    cargo
    (glWrap kitty)
    neovim

    maple-mono.NF-CN-unhinted
    nixGLIntel

    # 按需取消注释
    # eza
    # bat
    # zoxide
    # tmux
    # du-dust
    # Python
    (python3.withPackages (
      ps: with ps; [
        torch
        torchvision
        numpy  scipy  pandas  matplotlib  scikit-learn  scikit-image  networkx
        jupyterlab
      ]
    ))
  ];
}
