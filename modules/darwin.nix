{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.shellAliases = {
    xallow = "f(){ xattr -cr $1 }; f";
    xclear = "f(){ xattr -c $1 }; f";
    ghv = "gh repo view --web";
  };

  home.sessionVariables = {
    JAVA_HOME = "/opt/homebrew/opt/openjdk";
    PATH = "$HOME/.cargo/bin:$PATH";
  };

  home.packages = [
    pkgs.nixd
    pkgs.devbox
    pkgs.nil
  ];
}
