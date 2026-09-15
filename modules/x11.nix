{ config, pkgs, ... }:

# XWayland 侧的 HiDPI。
#
# 屏幕是 3072x1920 @ scale 2，但 XWayland 只暴露逻辑尺寸（1536x960）的 X screen，
# 于是 X11 程序默认按 1x 渲染，界面看着只有原生程序的一半。X 资源库里的 Xft.dpi
# 是 Qt/GTK 在 xcb 后端下判断逻辑 DPI 的依据：设成 96 * 2 就等于让它们按 2 倍缩放。
#
# 实测（本机，腾讯会议 3.26）：
#   Xft.dpi=192 -> 登录窗 377x669
#   清掉该资源 -> 登录窗 189x335
#
# Xwayland 由 xwayland-satellite 随会话拉起，服务因此先等 socket，再 merge；
# 本机 display 号固定为 :0（/tmp/.X11-unix/X0），若以后变成别的号需要同步改。
{
  systemd.user.services.xresources = {
    Unit = {
      Description = "Load Xft.dpi into the XWayland resource database";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [ "DISPLAY=:0" ];
      ExecStart =
        "${pkgs.bash}/bin/bash -c '"
        + "until [ -S /tmp/.X11-unix/X0 ]; do sleep 0.2; done; "
        + "exec ${pkgs.xrdb}/bin/xrdb -merge %h/.Xresources'";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
