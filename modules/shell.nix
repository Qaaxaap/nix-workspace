{ config, pkgs, ... }:

{
  # 默认空配置 —— Home Manager 不会接管任何 shell 配置文件。
  #
  # 将来如果想让 HM 管理 ~/.zshrc（原文件会被 -b hm-backup 自动备份），
  # 把下面的示例取消注释并 hm-switch 即可：
  #
  # programs.zsh = {
  #   enable = true;
  #
  #   shellAliases = {
  #     hm-switch = "nix run ~/nix -- switch -b hm-backup --flake ~/nix";
  #     hm-update = "nix flake update ~/nix";
  #   };
  #
  #   # 把你现有 ~/.zshrc 的内容搬进来
  #   initExtra = ''
  #     source ~/.p10k.zsh
  #     plugins... 等等
  #   '';
  # };
}
