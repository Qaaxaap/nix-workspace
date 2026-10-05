{
  description = "Qaaxaap's Home Manager configuration";

  inputs = {
    # Follow unstable, matching nixpkgs master.
    # To pin a stable release instead, use e.g.:
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    #   home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixGL = { url = "github:nix-community/nixGL"; inputs.nixpkgs.follows = "nixpkgs"; };
    home-manager = {
      url = "github:nix-community/home-manager";
      # Reuse our nixpkgs instead of home-manager's own copy.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # omp (oh-my-pi) coding agent; it ships its own Home Manager module,
    # wired up in modules/omp.nix.
    omp = {
      url = "github:can1357/oh-my-pi";
      # Reuse our nixpkgs instead of oh-my-pi's own copy.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Rust 官方 toolchain。用来替掉 nixpkgs 的 rustc/cargo/rustfmt/clippy，
    # 因为 nixpkgs 的 rustc 不带 rust-src 组件，rust-analyzer 会报
    # "can't load standard library, try installing rust-src"。
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, nixGL, omp, rust-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        # 提供 rust-bin.*，用于 modules/packages.nix 里的 Rust toolchain。
        overlays = [ rust-overlay.overlays.default ];
        config = {
          # Logseq 依赖的 electron 39 已 EOL，nixpkgs 将其标记为
          # insecure；必须在此显式放行，否则求值直接失败。
          permittedInsecurePackages = [ "electron-39.8.10" ];

          # 将来需要非自由包时取消注释:
          # allowUnfree = true;
        };
      };

      # 仓库里本地打包的包（上游没有 flake、nixpkgs 也没有）。
      # 定义一次，Home Manager 配置与下面暴露的 packages/overlays 共用同一个
      # derivation。
      plainva = pkgs.callPackage ./pkgs/plainva.nix { };

      # watch-skill —— agent 的视频理解引擎（CLI + MCP server）。
      # nixpkgs 里没有本体，但它的全部 Python 依赖 nixpkgs 都有，
      # 所以只需打包本体（详见 pkgs/watch-skill.nix 的注释）。
      watch-skill = pkgs.callPackage ./pkgs/watch-skill.nix { };
    in {
      # `nix fmt` support
      formatter.${system} = pkgs.nixfmt;

      # Standalone Home Manager (non-NixOS) configuration for this machine.
      # NOTE: the attribute name must match `home.username`, otherwise
      # `home-manager switch --flake ~/nix` cannot find it.
      homeConfigurations.Qaaxaap = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit nixGL omp plainva watch-skill; };
        modules = [
          ./home.nix
          ./modules/packages.nix
          ./modules/shell.nix
          ./modules/files.nix
          ./modules/x11.nix
          ./modules/omp.nix
        ];
      };

      # Convenience: `nix run ~/nix -- switch --flake ~/nix`
      apps.${system}.default = {
        type = "app";
        program = "${home-manager.packages.${system}.default}/bin/home-manager";
        meta.description = "Home Manager CLI";
      };

      # 供外部复用（详见 README「别人怎么用这个 flake」）：
      #   nix run github:Qaaxaap/nix-workspace#plainva
      #   nix build github:Qaaxaap/nix-workspace#plainva
      packages.${system} = {
        inherit plainva watch-skill;
        default = plainva;
      };

      #   nixpkgs.overlays = [ nix-workspace.overlays.default ];
      overlays.default = final: _: {
        plainva = final.callPackage ./pkgs/plainva.nix { };
        watch-skill = final.callPackage ./pkgs/watch-skill.nix { };
      };

      # Default dev shell: `nix develop ~/nix`.
      # Same toolset that Home Manager installs (single source of truth in
      # modules/packages.nix), plus git and the flake formatter.
      devShells.${system}.default = pkgs.mkShell {
        packages =
          self.homeConfigurations.Qaaxaap.config.home.packages
          ++ (with pkgs; [ git nixfmt ]);
      };
    };
}
