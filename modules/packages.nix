{ config, pkgs, ... }:

{
  # ============================================================
  # 纯包管理：这里的东西只装进 ~/.nix-profile，不生成/不覆盖
  # 任何配置文件。要装什么包，往下面加一行即可。
  # ============================================================
  home.packages = with pkgs; [
    # Nix 相关
    nix-output-monitor # nom build / nom develop
    nh
    neovim

    # 搜索 / 文件
    ripgrep
    fd
    fzf # 补全/按键绑定需自己在 .zshrc 里 source，见 README
    logseq

    # 常用 CLI
    jq
    tree
    htop
    direnv # 需自己在 .zshrc 加: eval "$(direnv hook zsh)"
    nvchecker  s-tui  scour  opencc
    pnpm
    cargo

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
