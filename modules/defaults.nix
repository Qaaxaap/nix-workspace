{ config, pkgs, ... }:

{
  # Session-wide environment variables.
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
    BROWSER = "firefox";
  };

  # Arbitrary files symlinked into the home directory, e.g.:
  #   home.file.".config/foo/bar.conf".source = ./dotfiles/foo.conf;

  # Packages that don't fit any of the other modules.
  home.packages = with pkgs; [
    nix-output-monitor # `nom build` / `nom develop` — prettier Nix output
  ];
}
