# pywalfox —— Pywalfox 浏览器扩展的 native messaging host。
#
# nixpkgs 没有这个包（截至 2026-10 unstable），PyPI 有源码；pacman 侧的
# python-pywalfox 是同一个 2.9.0。
#
# 打包要点：
#   * 上游 setup.py 要读 README.md 并 import pywalfox.config 取版本号，sdist
#     里两者都在，无需 postPatch。
#   * 资源文件（assets/css、assets/manifest.json、bin/）靠 MANIFEST.in +
#     include_package_data 进包，走 setuptools 默认流程即可。
#   * 无 python 依赖。配色从 ~/.cache/wal/colors.json 读，不由本包生成。
#   * Firefox 调用 native host 时按 `pywalfox <manifest路径> <扩展id>` 传参，
#     __main__.py 里已有对应分支，所以清单的 path 直接指向 bin/pywalfox 即可，
#     不需要再包一层 shell 脚本。
#
# 注意：native host 清单 ~/.mozilla/native-messaging-hosts/pywalfox.json 里
# host 名固定是 pywalfox，本机那份当前指向 Noctalia，二者互斥。本包只提供
# 命令，清单由使用方决定：
#   pywalfox install --executable "$(command -v pywalfox)"
{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "pywalfox";
  version = "2.9.0";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-ig3uT3rfp4YJMUkF8kXl2hu01/DRyuej2lbE4oTdNQE=";
  };

  doCheck = false;
  pythonImportsCheck = [ "pywalfox" ];

  meta = {
    description = "Native app used alongside the Pywalfox browser extension";
    homepage = "https://github.com/frewacom/pywalfox";
    license = lib.licenses.mpl20;
    mainProgram = "pywalfox";
    platforms = lib.platforms.unix;
  };
})
