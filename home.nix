{ config, pkgs, ... }:

{
  home.username = "Qaaxaap";
  home.homeDirectory = "/home/Qaaxaap";

  # Home Manager 兼容性标记，创建后不要随便改。
  home.stateVersion = "26.05";

  # 把 home-manager 命令本身装进用户 profile（不接管任何配置文件）。
  programs.home-manager.enable = true;

  # 少量"顺手"的包也可以直接加在这里：
  # home.packages = [ pkgs.xxx ];
}
