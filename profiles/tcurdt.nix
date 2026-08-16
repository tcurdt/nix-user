{
  pkgs,
  ...
}:
let
  inherit (pkgs) lib;

  gitConfig = (pkgs.formats.gitIni { }).generate "gitconfig" {
    user = {
      name = "Torsten Curdt";
      email = "tcurdt@vafer.org";
    };

    alias = {
      p = "push";
      r = "pull --rebase";
      rf = "pull --rebase --force";
      st = "status -s";
      sha = "rev-parse --short HEAD";
      ci = "commit -v";
      co = "checkout";
      clean = "!git restore . && git clean -fdx";
      a = "add";
      au = "add -u";
      aa = "add --all";
      t = "tag";
      td = "!f() { git tag -d $1; git push --delete origin $1; }; f";
      tf = "!f() { git tag -f $1; git push --force origin HEAD:refs/tags/$1; }; f";
      b = "branch -av";
      bd = "branch -D";
      ba = "!f() { git diff --binary HEAD...$1 | git apply; }; f";
      df = "diff --name-only";
      l = "log --graph --decorate --no-merges --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s' --date='format:%F %a'";
      la = "log --full-history --all --graph --abbrev-commit --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s' --date='format:%F %a'";
      lf = "log --graph --decorate --no-merges --oneline --name-status --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s %n' --date='format:%F %a'";
      lp = "log --abbrev-commit --date=relative -p";
      m = "!f() { git merge --squash \"$1\" && git commit && git branch -d \"$1\"; }; f";
      standup = "!f() { git log --since=$1.days --author=tcurdt --pretty=format':%Cgreen%cd:%Creset %s' --date='format:%F %a' --all; }; f";
      standupr = "!f() { git log --reverse --since=$1.days --author=tcurdt --pretty=format':%Cgreen%cd:%Creset %s' --date='format:%F %a' --all; }; f";
      export = "archive -o latest.tar.gz -9 --prefix=latest/";
      setup = "!git init && git add . && git commit -m init";
    };

    github.user = "tcurdt";
    gpg.format = "ssh";
    init.defaultBranch = "main";
    branch = {
      sort = "-committerdate";
      autosetuprebase = "always";
      autosetupmerge = "always";
    };
    push = {
      autosetupremote = true;
      default = "current";
      followTags = true;
    };
    "remote \"origin\"" = {
      tagopt = "--tags";
      prune = true;
      pruneTags = true;
    };
    pull = {
      rebase = true;
      ff-only = true;
    };
    rerere.enabled = true;
    rebase.updateRefs = true;
    merge.ff = "only";
    log.oneline = true;
    gist.private = true;
    gits.browse = true;
  };

  gitIgnore = pkgs.writeText "git-ignore" ''
    .sync
    .DS_Store
    _research
    *~
    .#*
    .env
  '';

  batConfig = pkgs.writeText "bat-config" ''
    --color=never
    --paging=never
  '';

  tmuxConfig = pkgs.writeText "tmux.conf" ''
    set -g clock-mode-style 24
  '';

  direnvConfig = (pkgs.formats.toml { }).generate "direnv.toml" {
    global.load_dotenv = false;
  };

  direnvrc = pkgs.writeText "direnvrc" ''
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
  '';
in
{
  packages = with pkgs; [
    nano
    zellij
    curl
    yq
    jq
    openssl
    unzip
    htop
    gitMinimal
    mmv
    file
    dnsutils
    doggo
    parallel
    just
    diceware
    xh
    pv
    croc
    sd
    fd
    eza
    bat
    procs
    ripgrep
    ruplacer
    dust
    nh
    nixfmt
    nil
    neovim
    tmux
    direnv
    nix-direnv
  ];

  shellAliases = {
    cat = "bat --style=plain";
    bat = "bat --style=numbers";
    ll = "eza -la --group --octal-permissions --no-permissions --time-style long-iso";
    ls = "eza";
    g = "git";
    vi = "nvim";
    vim = "nvim";
    tssh = "ssh -A -o UserKnownHostsFile=/dev/null ";
    passphrase = "diceware --no-caps -n 7 -d -";
    p = "pnpm";
    k = "kubectl";
    kall = "kubectl get all -A";
    dates = "echo -n 'UTC: ' && date_utc && echo -n 'BER: ' && date_berlin";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    date_utc = "date -u -Iseconds";
    date_berlin = "TZ=Europe/Berlin date -Iseconds";
    systemtime = "chronyc makestep && chronyc tracking";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    date_utc = ''date -u "+%Y-%m-%dT%H:%M:%SZ"'';
    date_berlin = ''TZ=Europe/Berlin date "+%Y-%m-%dT%H:%M:%S%z"'';
    xallow = ''f(){ xattr -cr "$1"; }; f'';
    xclear = ''f(){ xattr -c "$1"; }; f'';
  };

  sessionPath = [
    "go/bin"
    ".bin"
  ];

  sessionVariables = {
    PAGER = "less";
    EDITOR = "nano";
    CLICOLOR = 1;
  };

  bashInit = ''
    eval "$(${pkgs.direnv}/bin/direnv hook bash)"
  '';

  files = {
    ".config/git/config" = gitConfig;
    ".config/git/ignore" = gitIgnore;
    ".config/bat/config" = batConfig;
    ".config/direnv/direnv.toml" = direnvConfig;
    ".config/direnv/direnvrc" = direnvrc;
    ".tmux.conf" = tmuxConfig;
  };
}
