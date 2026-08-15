{ lib, pkgs, ... }:
{
  home.packages = [

    pkgs.nano
    pkgs.helix

    pkgs.gitMinimal
    # pkgs.jujutsu

    pkgs.curl
    pkgs.xh
    pkgs.croc
    # pkgs.zrok # waiting for darwin

    # pkgs.tmux # via config
    # pkgs.zellij # tmux
    (pkgs.writeShellScriptBin "mssh" ''
      exec ssh -t "$@" "tmux new -A -s tcurdt"
    '')

    # mine.envq
    pkgs.yq
    pkgs.jq
    pkgs.openssl
    pkgs.diceware
    pkgs.unzip
    pkgs.htop

    pkgs.nh
    pkgs.nixfmt
    # pkgs.nvd
    # pkgs.nix-output-monitor

    # pkgs.lesspipe # via config
    # pkgs.nushell
    # pkgs.carapace # option completion
    # pkgs.starship # prompt
    pkgs.mmv
    pkgs.file
    pkgs.dnsutils
    pkgs.doggo # dns client
    pkgs.parallel
    pkgs.just
    pkgs.pv
    pkgs.zoxide # better cd
    pkgs.eza # better ls
    pkgs.bat # better cat
    pkgs.procs # better ps
    pkgs.fd # better find
    pkgs.sd # better sed
    pkgs.ripgrep # better grep
    pkgs.ruplacer
    pkgs.dust # better du
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      __prompt_git_segment() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

        local branch
        branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"

        git diff --quiet --ignore-submodules HEAD 2>/dev/null
        local dirty=""
        [ $? -ne 0 ] && dirty="*"

        printf " (%s%s)" "$branch" "$dirty"
      }

      PS1='\[\e[32m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\]\[\e[33m\]$(__prompt_git_segment)\[\e[0m\]\n\[\e[31m\]\$\[\e[0m\] '
    '';
  };

  programs.git = {
    enable = true;

    package = pkgs.gitMinimal;

    ignores = [
      ".sync"
      ".DS_Store"
      "_research"
      "*~"
      ".#*"
      ".env"
    ];

    settings = {
      user.name = "Torsten Curdt";
      user.email = "tcurdt@vafer.org";

      alias = {
        p = "push";

        r = "pull --rebase";
        rf = "pull --rebase --force";

        st = "status -s";
        sha = "rev-parse --short HEAD";

        ci = "commit -v";
        co = "checkout";

        # go back to the pure branch and remove files that don't belong
        clean = "!git restore . && git clean -fdx";

        a = "add";
        au = "add -u";
        aa = "add --all";

        t = "tag";

        # delete a tag
        td = "!f() { git tag -d $1; git push --delete origin $1; }; f";

        # force a tag
        tf = "!f() { git tag -f $1; git push --force origin HEAD:refs/tags/$1; }; f";

        b = "branch -av";

        # delete a branch
        bd = "branch -D";

        # apply a branch as local changes
        ba = "!f() { git diff --binary HEAD...$1 | git apply; }; f";

        # only show the files changed
        df = "diff --name-only";

        l = "log --graph --decorate --no-merges --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s' --date='format:%F %a'";

        # like l, but across all refs/branches with full history
        la = "log --full-history --all --graph --abbrev-commit --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s' --date='format:%F %a'";

        # compact log with changed files per commit (name-status), no merges
        lf = "log --graph --decorate --no-merges --oneline --name-status --pretty=format:'%Cred%h %Cblue%cN %Cgreen%cd%C(yellow)%d%Creset - %s %n' --date='format:%F %a'";

        # log with full patch output (-p) and relative dates
        lp = "log --abbrev-commit --date=relative -p";

        # merge a feature branch
        m = "!f() { git merge --squash \"$1\" && git commit && git branch -d \"$1\"; }; f";

        standup = "!f() { git log --since=$1.days --author=tcurdt --pretty=format':%Cgreen%cd:%Creset %s' --date='format:%F %a' --all; }; f";
        standupr = "!f() { git log --reverse --since=$1.days --author=tcurdt --pretty=format':%Cgreen%cd:%Creset %s' --date='format:%F %a' --all; }; f";
        export = "archive -o latest.tar.gz -9 --prefix=latest/";
        setup = "!git init && git add . && git commit -m init";
      };

      github.user = "tcurdt";
      gpg.format = "ssh";
      init.defaultBranch = "main";
      branch.sort = "-committerdate";
      branch.autosetuprebase = "always";
      branch.autosetupmerge = "always";
      push.autosetupremote = true;
      push.default = "current";
      push.followTags = 1;
      remote.origin.tagopt = "--tags";
      remote.origin.prune = true;
      remote.origin.prunetags = true;
      pull.rebase = 1;
      pull.ff-only = 1;
      rerere.enabled = 1;
      rebase.updateRefs = true;
      merge.ff = "only";
      log.oneline = 1;
      gist.private = 1;
      gits.browse = 1;
    };
  };

  programs.bat = {
    enable = true;
    config = {
      color = "never";
      paging = "never";
    };
  };

  # programs.neovim = {
  #   enable = true;
  #   viAlias = true;
  #   vimAlias = true;
  #   extraConfig = "";
  #   plugins = [ ];
  # };

  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    baseIndex = 1;
    historyLimit = 20000;
    escapeTime = 0;

    extraConfig = ''
      unbind -a

      bind -T root -N "Switch to window 1" M-1 select-window -t 1
      bind -T root -N "Switch to window 2" M-2 select-window -t 2
      bind -T root -N "Switch to window 3" M-3 select-window -t 3
      bind -T root -N "Switch to window 4" M-4 select-window -t 4
      bind -T root -N "Switch to window 5" M-5 select-window -t 5
      bind -T root -N "Switch to window 6" M-6 select-window -t 6
      bind -T root -N "Switch to window 7" M-7 select-window -t 7
      bind -T root -N "Switch to window 8" M-8 select-window -t 8
      bind -T root -N "Switch to window 9" M-9 select-window -t 9

      bind -T root -N "Create a new window" M-n new-window

      bind -T root -N "Select pane to the left"  M-Left  if -F "#{pane_at_left}"   "" "select-pane -L"
      bind -T root -N "Select pane below"        M-Down  if -F "#{pane_at_bottom}" "" "select-pane -D"
      bind -T root -N "Select pane above"        M-Up    if -F "#{pane_at_top}"    "" "select-pane -U"
      bind -T root -N "Select pane to the right" M-Right if -F "#{pane_at_right}"  "" "select-pane -R"

      bind -T root   -N "Enter split-pane mode" M-s switch-client -T split
      bind -T split  -N "Split left"   Left  split-window -hb
      bind -T split  -N "Split right"  Right split-window -h
      bind -T split  -N "Split above"  Up    split-window -vb
      bind -T split  -N "Split below"  Down  split-window -v

      # arrows to navigate, v to select, y to yank
      bind -T root -N "Enter copy mode" M-c copy-mode

      bind -T root -N "Save buffer to file" M-w if -F "#{buffer_size}" {
        choose-buffer {
          command-prompt -p "Save to path:" {
            save-buffer -b %% "%%"
          }
        }
      } {
        display-message "No buffers to save"
      }

      bind -T root -N "Detach from session" M-d detach-client

      bind -T root  -N "Open command prompt" : command-prompt
      bind -T split -N "Open command prompt" : command-prompt

      bind -T root  -N "List key bindings"       ? list-keys -N -T root
      bind -T split -N "List split key bindings" ? list-keys -N -T split

      # set -g status-style          "bg=black,fg=white"
      # set -g status-left           "[#{session_name}] "
      # set -g status-left-length    20
      # set -g status-right          "#{?client_key_table,[#{client_key_table}] ,}%H:%M"
      # set -g status-right-length   30
    '';
  };

  home.shellAliases = {
    cat = "bat --style=plain";
    bat = "bat --style=numbers";
    ll = "eza -la --group --octal-permissions --no-permissions --time-style long-iso";
    ls = "eza";
    g = "git";
    tssh = "ssh -A -o UserKnownHostsFile=/dev/null ";
    passphrase = "diceware --no-caps -n 7 -d -";

    date_utc = "date -u -Iseconds";
    date_berlin = "TZ=Europe/Berlin date -Iseconds";
    dates = "echo -n 'UTC: ' && date_utc && echo -n 'BER: ' && date_berlin";
    systemtime = "chronyc makestep && chronyc tracking";

    p = "pnpm";
    k = "kubectl";
    kall = "kubectl get all -A";
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = false;
      };
    };
  };

  programs.less = {
    enable = true;
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.bin"
  ];

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "nano";
    CLICOLOR = 1;
    # LESSOPEN = "|${pkgs.lesspipe}/bin/lesspipe %s";
    # LESS = "-R";
  };

  home.stateVersion = lib.mkDefault "25.11";
}
