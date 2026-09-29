# watch-skill —— 给 agent 装上「眼睛和耳朵」的视频理解引擎（Python CLI + MCP server）。
#
# 上游既不提供 flake，也不在 nixpkgs 里（截至 2026-09 nixpkgs unstable 无
# watch-skill 属性，也没有相关 PR/NUR 包），所以这里按 nixpkgs 的
# buildPythonApplication 从源码打包。
#
# 打包方式要点：
#   * 全部 Python 依赖 nixpkgs 都有，本体是唯一需要打包的部分。
#     （fastmcp 与 fastmcp-slim 在 nixpkgs 里成对存在——4.x 起 fastmcp 变成
#      只转发到 fastmcp-slim 的元包，nixpkgs 两个都打了。）
#   * Python 固定用 python314Packages：本机系统 python3 是 3.14，与 venv 里的
#     解释器一致，避免 ABI/wheel 层面的意外。
#   * 显式列出 dependencies 等于上游 pyproject 的
#     extras = [perceive, ocr, whisper, index, mcp]。若直接 buildPythonPackage
#     让 hook 读 pyproject，它会去解析全部 extras，其中 loop(playwright) /
#     diarize(pyannote, 拉 torch) / crewai 等既重又不是本项目所需。
#   * 刻意不打包的 extras：
#       loop     —— Playwright 浏览器捕获，需要下载 chromium，按需再加；
#       api      —— REST surface，按需再加 fastapi/uvicorn；
#       attest   —— Ed25519 签名，按需再加 cryptography；
#       框架适配器（langchain/crewai/llamaindex/autogen/openai-agents）不需要。
#   * ffmpeg / yt-dlp 是**运行时二进制**，不是 Python 依赖，必须 wrap 进 PATH，
#     否则 watch-skill doctor 会报找不到。deno 用于 yt-dlp 的部分 extractor。
#   * 上游 sdist 里带了一个 ~5MB 的 docs/ 与内置 bench，我们在 postPatch 里删掉，
#     只保留运行所需的包体。
{
  lib,
  python314Packages,
  ffmpeg,
  yt-dlp,
  deno,
  makeWrapper,
  nix-update-script,
}:

let
  py = python314Packages;
in
py.buildPythonApplication (finalAttrs: {
  pname = "watch-skill";
  version = "1.4.3";

  src = py.fetchPypi {
    pname = "watch_skill"; # PyPI 上的项目名用下划线
    inherit (finalAttrs) version;
    # 不写 format：nixpkgs 的 fetchPypi 只支持 "wheel" / "setuptools"，
    # 默认 "setuptools" 即从 sdist 构建（本包 sdist 里带 setup.py）。
    hash = "sha256-NnbcuNuuH0J50B9be13KaAxadDBQxssVBqGu7qks+6c=";
  };

  # 上游用 hatchling 作构建后端；pyproject.toml 里 build-backend 已声明，
  # 这里只需把 hatchling 放进 buildPythonPackage 的构建环境（--no-isolation）。
  pyproject = true;
  build-system = [ py.hatchling ];

  # = 上游 pyproject 的 extras 并集（perceive/ocr/whisper/index/mcp）。
  # 版本核对（nixpkgs unstable，2026-09）：
  #   ✅ 满足：fastmcp 3.4.7(>=3.4,<4)、fastembed 0.8.0(>=0.8,<0.9)、
  #            onnxruntime 1.27.1(>=1.27,<2)、faster-whisper 1.2.1、
  #            rapidocr 3.9.2、scenedetect 0.6.7.1、imagehash 4.3.2、
  #            ctranslate2 4.8.2、rich 15.0.0、httpx 0.28.1、pydantic 2.13.4
  #   ⚠️ 松绑：typer 0.25.1(上游要 >=0.26)、pydantic-settings 2.12.0(上游要 >=2.14)
  #      —— 见下方 pythonRelaxDeps 的说明。
  dependencies = [
    py.typer
    py.pydantic
    py.pydantic-settings
    py.rich
    py.httpx
    # perceive
    py.numpy
    py.pillow
    py.opencv4
    py.scenedetect
    py.imagehash
    # ocr
    py.rapidocr
    py.onnxruntime
    py.python-bidi
    # whisper
    py.faster-whisper
    py.ctranslate2
    # index
    py.fastembed
    # mcp
    py.fastmcp
  ];

  # nixpkgs 的 typer(0.25.1) / pydantic-settings(2.12.0) 比上游下限略旧。
  # 两者都是同主版本内的小版本差，且 watch-skill 只用到稳定 API
  # （typer 的 Typer/app.command、pydantic-settings 的 BaseSettings），
  # 因此松绑元数据让构建通过。若运行时报错，改成在这里 override 这两个包到
  # PyPI 最新版（typer 0.27.2 / pydantic-settings 2.15.0）。
  pythonRelaxDeps = [ "typer" "pydantic-settings" ];

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    # 上游用 hatch-fancy-pypi-readme 从远端 GitHub 拼 README（其相对路径只在
    # 仓库里成立，sdist 里直接带 README.md）。Nix 构建无网络，也不需要那段
    # 渲染后的长描述，所以：
    #   1) 把 dynamic readme 换成静态文件引用；
    #   2) 把 build-system.requires 收窄成只依赖 hatchling —— 原值是单行内联的
    #      `requires = ["hatchling", "hatch-fancy-pypi-readme"]`，直接删名字会
    #      留下非法的 `["hatchling", ]`，所以整行替换；
    #      pypaBuildPhase 还会校验 requires 里每一项都已安装。
    sed -i 's/dynamic = \["readme"\]/readme = "README.md"/' pyproject.toml
    sed -i 's/^requires = .*/requires = ["hatchling"]/' pyproject.toml
    #   3) 删掉 [tool.hatch.metadata.hooks.fancy-pypi-readme] 整段（含其中的
    #      fragments / substitutions 子表），否则 hatchling 会报
    #      "Unknown metadata hook: fancy-pypi-readme"。
    sed -i '/^\[tool\.hatch\.metadata\.hooks\.fancy-pypi-readme\]/,/^\[tool\.pytest/{/^\[tool\.pytest/!d}' pyproject.toml

    # 扔掉文档与内置基准，只留运行包体（sdist 约 5.6MB，其中大部分是 docs）。
    rm -rf docs bench
  '';

  postInstall = ''
    wrapProgram "$out/bin/watch-skill" \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg yt-dlp deno ]}
  '';

  # 上游测试需要真实视频与网络，Nix 构建沙箱里跑不了。
  doCheck = false;
  pythonImportsCheck = [ "watch_skill" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Give any agent a video input: watch, index, ask, and iterate on video via MCP, CLI, REST, and Python";
    homepage = "https://github.com/oxbshw/watch-skill";
    changelog = "https://github.com/oxbshw/watch-skill/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "watch-skill";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
