{ config, pkgs, ... }:

{
  home.username = "Qaaxaap";
  home.homeDirectory = "/home/Qaaxaap";

  # Home Manager 兼容性标记，创建后不要随便改。
  home.stateVersion = "26.05";

  # 把 home-manager 命令本身装进用户 profile（不接管任何配置文件）。
  programs.home-manager.enable = true;

  xdg.enable=true;
  xdg.mime.enable=true;
  targets.genericLinux.enable=true;

  # GUI 会话（systemd user）不会自动带上 nix profile 的 bin，
  # 桌面启动的 VSCodium 就找不到 nvim（vscode-neovim 需要它）。
  home.sessionPath = [ "$HOME/.nix-profile/bin" ];
  # 少量"顺手"的包也可以直接加在这里：
  # home.packages = [ pkgs.xxx ];
}
