{ config, pkgs, omp, ... }:
let
  zshCompletion = pkgs.runCommandLocal "omp-zsh-completion" { } ''
    mkdir -p $out
    HOME=$TMPDIR ${config.programs.omp.package}/bin/omp completions zsh > $out/_omp
  '';
in
{
  imports = [ omp.homeManagerModules.default ];

  programs.omp.enable = true;

  home.file.".zsh/completions/_omp".source = "${zshCompletion}/_omp";
}
