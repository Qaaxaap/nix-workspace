# omp（oh-my-pi）—— 直接用上游 release 的预编译二进制。
#
# 为什么不用 flake input `github:can1357/oh-my-pi` 里那份包：它从源码构建
# （Rust 一整套 + Bun 打包），一次二十分钟左右；上游 flake 虽然声明了
# nix-community 的 cachix，但那边并没有对应产物（查过，path is not valid），
# 所以每次跟着 flake update 升级都得本地重编。
#
# 上游 release 提供 omp-linux-x64：一个 ELF，Bun 运行时与原生模块都打进去了，
# 动态依赖只有 glibc 的基础库（libc/libpthread/libdl/libm），因此这里只要
# 装文件 + autoPatchelf 改 interpreter 即可。升级改 version 与 hash
# （hash 直接取 release 里 SHA256SUMS.txt 的那一行）。
{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "omp";
  version = "18.6.1";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${finalAttrs.version}/omp-linux-x64";
    hash = "sha256-ySpoRtAphOhPB8Y2LRit03g/Uo9JT/zx4PJuWU8ydGM=";
  };

  dontUnpack = true;

  # Bun 的单文件可执行文件把运行时和入口按 ELF 布局嵌在一起，patchelf 改
  # interpreter/rpath、或者 strip，都会破坏它，表现是运行时退化成 bun 自己的
  # CLI（`omp --version` 输出 bun 的版本号，`omp --help` 显示 bun 的用法）。
  # 本机是 LFS，系统里本来就有 /lib64/ld-linux-x86-64.so.2，所以原样装进去就能跑；
  # AUR 的 oh-my-pi-bin 同样是 options=('!strip')。
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/omp"
    runHook postInstall
  '';

  meta = {
    description = "OMP (oh-my-pi) coding agent, upstream prebuilt binary";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "omp";
  };
})
