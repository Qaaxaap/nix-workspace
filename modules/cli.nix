{ config, pkgs, ... }:

{
  programs = {
    git = {
      enable = true;
      userName = "Qaaxaap";
      userEmail = "lkn15289353760@126.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "vim";
      };
    };

    # Automatically loads .envrc; with nix-direnv it evaluates
    # `use flake` / `use nix` in a cached nix shell.
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      # defaultOptions = [ "--height 40%" "--border" ];
    };
  };

  home.packages = with pkgs; [
    ripgrep # fast grep (rg)
    fd      # fast find
    jq      # JSON processing
    tree    # directory listing
    htop    # process viewer
    # eza      # modern ls replacement
    # bat      # cat with syntax highlighting
    # zoxide   # smarter cd
    # du-dust  # disk usage
  ];
}
