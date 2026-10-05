# VSCodium 扩展清单。
#
# 全部取自 open-vsx（VSCodium 的默认扩展市场），逐个固定版本与哈希，
# 由 nix 构建成 $out/share/vscode/extensions/<publisher>.<name>，
# 再经 with-extensions.nix 以 --extensions-dir 注入编辑器。
#
# 因此扩展目录是 store 里的只读目录，UI 里装不了/更新不了扩展；
# 想加扩展就往下面列表里加一条。
#
# 升级某个扩展：
#   1. 查最新版本与下载地址
#        curl -s https://open-vsx.org/api/<ns>/<name>/latest | jq '{version, download: .files.download}'
#   2. 取哈希（输出即 SRI 形式，可直接填进 hash）
#        nix store prefetch-file --json --hash-type sha256 '<files.download>'
#   3. 改下面的 version 与 hash。
{ pkgs }:
let
  inherit (pkgs.vscode-utils) buildVscodeExtension;

  # open-vsx 的下载地址形如
  #   https://open-vsx.org/api/<ns>/<name>/<ver>/file/<ns>.<name>-<ver>.vsix
  # namespace 的大小写按 open-vsx 注册的写法（GitHub、MS-CEINTL）。
  fromOpenVsx =
    {
      namespace,
      name,
      version,
      hash,
    }:
    buildVscodeExtension {
      pname = name;
      vscodeExtPublisher = namespace;
      vscodeExtName = name;
      vscodeExtUniqueId = "${namespace}.${name}";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://open-vsx.org/api/${namespace}/${name}/${version}/file/${namespace}.${name}-${version}.vsix";
        inherit hash;
      };
    };
in
[
  (fromOpenVsx {
    namespace = "GitHub";
    name = "github-vscode-theme";
    version = "6.3.5";
    hash = "sha256-qFI2pYrUkLFgDsWg/QzqfuxW+50zZgoayCxtpjmtOvQ=";
  })
  (fromOpenVsx {
    namespace = "GitHub";
    name = "vscode-github-actions";
    version = "0.32.3";
    hash = "sha256-BYRiFiyynU0iNB2RLBXc+iGUd0sekvww/LoabKPJGr0=";
  })
  (fromOpenVsx {
    namespace = "GitHub";
    name = "vscode-pull-request-github";
    version = "0.166.1";
    hash = "sha256-iYofJk5dSQZ4Fd9boE9jQK3euJ5VyUmimVwxgdjAUkk=";
  })
  (fromOpenVsx {
    namespace = "MS-CEINTL";
    name = "vscode-language-pack-zh-hans";
    version = "1.131.0";
    hash = "sha256-f/ydvpgPlZQu1WdSwdbKX0CFUBOu3TTPQCV5Kb5NGJU=";
  })
  (fromOpenVsx {
    namespace = "rust-lang";
    name = "rust-analyzer";
    version = "0.4.3072";
    hash = "sha256-k1McVRxEDI8jxcV9ZCY84IpLgktuY8iHyH2woi1YB3g=";
  })
  (fromOpenVsx {
    namespace = "tamasfe";
    name = "even-better-toml";
    version = "0.21.2";
    hash = "sha256-89xE8cVR7e85ennw+MXbQGbGpUfiELXDzsRAC/FzsAg=";
  })
  (fromOpenVsx {
    namespace = "zokugun";
    name = "cron-tasks";
    version = "0.2.1";
    hash = "sha256-nfAQzlZfUFy1DzKhp/q2WqnGnzMdPukuTa4qsqysIro=";
  })
  (fromOpenVsx {
    namespace = "zokugun";
    name = "sync-settings";
    version = "0.21.2";
    hash = "sha256-dmytAV6X6ORdHzjhhPyC7vuvovXAEBQwAVuTo7ZecbY=";
  })
]
