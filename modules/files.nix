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
      # vsc-dots：VSCodium 的设置与快捷键（扩展清单在同目录，由 flake 构建）。
      # 只链接这两个文件：User/ 下还有 globalStorage、workspaceStorage、
      # History 等运行时数据，不能整个目录接管。
      "VSCodium/User/settings.json".source = link "${config.home.homeDirectory}/nix/config/vsc-dots/User/settings.json";
      "VSCodium/User/keybindings.json".source = link "${config.home.homeDirectory}/nix/config/vsc-dots/User/keybindings.json";
    };
    home.file = {
      ".zshrc".source = link "${config.home.homeDirectory}/nix/config/zshrc";
      # 环境变量单一来源：交互 zsh 与 dsh 的 zsh 工具都 source 它。
      ".zsh-env".source = link "${config.home.homeDirectory}/nix/config/zsh-env";
      ".p10k.zsh".source = link "${config.home.homeDirectory}/nix/config/p10k.zsh";
      ".oh-my-zsh".source = link "${config.home.homeDirectory}/nix/config/oh-my-zsh";
      # XWayland 应用的 Xft.dpi；由 systemd user 服务 xresources 加载（modules/x11.nix）。
      ".Xresources".source = link "${config.home.homeDirectory}/nix/config/Xresources";
    };
    xdg.dataFile = {
      "icons/hicolor/512x512/apps/logseq.png".source = "${pkgs.logseq}/share/icons/hicolor/512x512/apps/logseq.png";
      "icons/hicolor/index.theme".source = "${pkgs.hicolor-icon-theme}/share/icons/hicolor/index.theme";
    };
}
