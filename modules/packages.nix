{ config, pkgs, nixGL, plainva, watch-skill, vscodium-electron-ext, d2l, pywalfox, ... }:
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
    # Plainva（本地优先的 Markdown vault 编辑器）：上游没有 flake/nixpkgs 包，
    # 由 pkgs/plainva.nix 从源码打包；flake 里定义成 `plainva` 传进来，
    # 同时也通过 packages/overlays 暴露给外部复用。
    plainva

    # watch-skill：agent 的视频理解引擎（watch/ask/search → 带时间戳的证据）。
    # 同样由 pkgs/watch-skill.nix 本地打包；ffmpeg / yt-dlp / deno 已由该包
    # 通过 wrapProgram 注入 PATH，无需在这里重复列出。
    watch-skill

    # 常用 CLI
    jq
    tree
    htop
    direnv # 需自己在 .zshrc 加: eval "$(direnv hook zsh)"
    nvchecker  s-tui  scour  opencc
    pnpm

    # Rust 工具链。改用 rust-overlay 的官方 toolchain（flake.nix 里加的
    # overlay），四件套依然同源。关键是多装 rust-src 组件：nixpkgs 的
    # rustc 不含标准库源码，rust-analyzer 会报
    # "can't load standard library, try installing rust-src"。
    # rust-src 落在 toolchain 的 lib/rustlib/src/rust，rust-analyzer 从
    # sysroot 自己就能找到，不必再设 RUST_SRC_PATH。
    # 用 minimal 而不是 default：default profile 会连 rust-docs 一起装，
    # 白占 706 MiB；rustfmt / clippy 单独列进 extensions 即可。
    # cargo-fmt 由 rustfmt 提供，cargo-clippy / clippy-driver 由 clippy 提供，
    # rustc 自带 rustdoc / rust-gdb / rust-lldb。
    (rust-bin.stable."1.98.1".minimal.override {
      extensions = [ "rust-src" "rustfmt" "clippy" ];
    })

    # VSCodium：编辑器本体是官方 RPM + nixpkgs 的 electron（pkgs/vscodium-electron.nix），
    # 扩展来自 config/vsc-dots（open-vsx 上逐个固定版本，经 --extensions-dir 注入），
    # 配置也由那份 vsc-dots 用符号链接管理。
    vscodium-electron-ext

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
    # Python。d2l 不在 nixpkgs 里（见 pkgs/d2l.nix），用 packageOverrides 注进
    # 包集合，withPackages 才认得 ps.d2l。
    ((python3.override {
      packageOverrides = _: _: { inherit d2l; };
    }).withPackages (ps: with ps; [
      torch
      torchvision
      numpy  scipy  pandas  matplotlib  scikit-learn  scikit-image  networkx
      jupyterlab
      # 以下对应 pacman 侧的 python-* 显式包，系统那份将逐步卸掉，
      # 卸载前先在这里补齐，保证功能不缺。beartype 还额外解决
      # python-beartype 更新被 check 卡住的问题。
      beartype  xarray  opencv4  onnxruntime  ctranslate2  pymupdf  rawpy
      markdown  safetensors  huggingface-hub  mkdocs-material  py-key-value-aio
      pytest  pytest-asyncio
      d2l
    ]))

    # Pywalfox 扩展的 native host。本机那份清单现在指向 Noctalia，两者抢同一个
    # host 名，要用这个包得先改清单（见 pkgs/pywalfox.nix 顶部注释）。
    pywalfox
  ];
}
