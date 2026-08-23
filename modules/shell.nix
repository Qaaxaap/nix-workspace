{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;

    # History behaviour
    historySize = 10000;
    historyFileSize = 100000;
    historyIgnore = [ "ls" "cd" "exit" "clear" "pwd" ];
    shellOptions = [ "histappend" "checkwinsize" "cmdhist" ];

    shellAliases = {
      l = "ls -CF";
      la = "ls -A";
      ll = "ls -lh";
      lt = "ls -lhtr";
      hm-switch = "nix run ~/nix -- switch --flake ~/nix";
      hm-update = "nix flake update ~/nix";
    };

    bashrcExtra = ''
      # coloured output for ls & friends (GNU coreutils)
      alias ls='ls --color=auto'
      alias grep='grep --color=auto'
    '';
  };

  # Fancy prompt — uncomment and run `nix run ~/nix -- switch` again:
  # programs.starship = {
  #   enable = true;
  #   settings = { add_newline = false; };
  # };
}
