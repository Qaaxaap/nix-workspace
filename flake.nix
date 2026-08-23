{
  description = "Qaaxaap's Home Manager configuration";

  inputs = {
    # Follow unstable, matching nixpkgs master.
    # To pin a stable release instead, use e.g.:
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    #   home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      # Reuse our nixpkgs instead of home-manager's own copy.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # `nix fmt` support
      formatter.${system} = pkgs.nixfmt;

      # Standalone Home Manager (non-NixOS) configuration for this machine.
      # NOTE: the attribute name must match `home.username`, otherwise
      # `home-manager switch --flake ~/nix` cannot find it.
      homeConfigurations.Qaaxaap = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          ./modules/packages.nix
          ./modules/shell.nix
        ];
      };

      # Convenience: `nix run ~/nix -- switch --flake ~/nix`
      apps.${system}.default = {
        type = "app";
        program = "${home-manager.packages.${system}.default}/bin/home-manager";
        meta.description = "Home Manager CLI";
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
