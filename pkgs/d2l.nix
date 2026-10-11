# d2l —— 《动手学深度学习》配套的辅助函数包（d2l.torch 等）。
#
# nixpkgs 没有这个包（截至 2026-10 unstable 无 d2l 属性），PyPI 上最新仍是
# 2023 年的 1.0.3，与 pacman 侧 python-d2l 同版本。学习仓库
# ~/Projects/d2l-tutor 用它跑练习。
#
# 打包要点：
#   * sdist 是 setuptools 打的纯 python 包，本体只有一个 d2l/ 目录，
#     __init__.py 里只有 __version__，真正 import 的是 d2l.torch 等后端模块。
#   * PyPI 元数据把依赖全部钉死在 2023 年的版本（numpy==1.23.5、
#     matplotlib==3.7.2、pandas==2.0.3 等），nixpkgs 的对应包领先好几个主版本，
#     因此整体松绑。实际用法 `from d2l import torch as d2l` 只用到 numpy/torch
#     的稳定 API，系统上同样是 d2l 1.0.3 配 numpy 2.5 的组合，已验证可跑。
#   * 依赖里的 jupyter 是元包（上游写死 jupyter==1.0.0），nixpkgs 有同名属性。
#   * 上游 sdist 不带测试，关掉 doCheck。
{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonPackage (finalAttrs: {
  pname = "d2l";
  version = "1.0.3";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-tplkNU+BUNGuAhZtHszWIsYfMwv2GiO65hS+T7Wc474=";
  };

  pythonRelaxDeps = [
    "jupyter"
    "numpy"
    "matplotlib"
    "matplotlib-inline"
    "requests"
    "pandas"
    "scipy"
  ];

  dependencies = with python3Packages; [
    jupyter
    numpy
    matplotlib
    matplotlib-inline
    requests
    pandas
    scipy
  ];

  doCheck = false;
  pythonImportsCheck = [ "d2l" ];

  meta = {
    description = "Dive into Deep Learning book utilities (PyTorch / MXNet / JAX / TensorFlow helper functions)";
    homepage = "https://d2l.ai";
    license = lib.licenses.mit0;
    platforms = lib.platforms.unix;
  };
})
