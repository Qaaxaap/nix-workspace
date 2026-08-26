{ config, pkgs, ... }:
let
  # 1
  link = config.lib.file.mkOutOfStoreSymlink;
in
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
    xdg.configFile = {
      "nvim".source = link "${config.home.homeDirectory}/nix/config/nvim-dots";
      "kitty".source = link "${config.home.homeDirectory}/nix/config/kitty";
    };
    home.file = {
      ".zshrc".source = link "${config.home.homeDirectory}/nix/config/zshrc";
      ".p10k.zsh".source = link "${config.home.homeDirectory}/nix/config/p10k.zsh";
      ".oh-my-zsh".source = link "${config.home.homeDirectory}/nix/config/oh-my-zsh";
    };
    xdg.dataFile = {
      "icons/hicolor/512x512/apps/logseq.png".source = "${pkgs.logseq}/share/icons/hicolor/512x512/apps/logseq.png";
      "icons/hicolor/index.theme".source = "${pkgs.hicolor-icon-theme}/share/icons/hicolor/index.theme";
    };
}
