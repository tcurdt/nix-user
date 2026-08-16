set quiet

check:
    nix flake check --all-systems path:.
    nix-instantiate --parse modules/profiles.nix > /dev/null
    nix-instantiate --parse profiles/tcurdt.nix > /dev/null
