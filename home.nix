{ config, pkgs, ... }:

{
  home.username = "Qaaxaap";
  home.homeDirectory = "/home/Qaaxaap";

  # The Home Manager release this configuration was created with.
  # Do NOT bump this casually: it controls backwards-compatibility
  # migrations. Read the release notes before changing it.
  home.stateVersion = "26.05";

  # Keep Home Manager itself in the user profile.
  programs.home-manager.enable = true;

  # Standard XDG base directories (~/.config, ~/.cache, ...) and env vars.
  xdg.enable = true;
}
