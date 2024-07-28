# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.

# Updates
zstyle ':z4h:'                  auto-update            no
zstyle ':z4h:'                  auto-update-days       28
zstyle ':z4h:*'                 channel                testing

# Autosuggestion
zstyle ':z4h:autosuggestions'   forward-char           partial-accept
zstyle ':z4h:autosuggestions'   end-of-line            partial-accept
zstyle ':z4h:fzf-complete'      recurse-dirs           no
# zstyle ':z4h:fzf-dir-history'   fzf-bindings           tab:repeat
# zstyle ':z4h:fzf-complete'      fzf-bindings           tab:repeat
# zstyle ':z4h:cd-down'           fzf-bindings           tab:repeat

# Shell title
zstyle ':z4h:term-title:ssh'    precmd                 ${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'
zstyle ':z4h:term-title:ssh'    preexec                ${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
# zstyle ':z4h:term-title:ssh' precmd  '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'
# zstyle ':z4h:term-title:ssh' preexec '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'

# Shell
zstyle ':z4h:command-not-found' to-file                "$TTY"
zstyle ':z4h:'                  term-shell-integration yes
zstyle ':z4h:'                  propagate-cwd          yes
zstyle ':z4h:'                  prompt-height          4
zstyle ':z4h:'                  prompt-at-bottom       no

# Search
zstyle ':zle:up-line-or-beginning-search'    leave-cursor       no
zstyle ':zle:down-line-or-beginning-search'  leave-cursor       no

# Completion config
zstyle ':completion:*'                       sort               false
zstyle ':completion:*:ls:*'                  list-dirs-first    true
zstyle ':completion:*:ssh:argument-1:'       tag-order          hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order          hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

# SSH Agent configuration
zstyle :omz:plugins:ssh-agent      agent-forwarding             yes
zstyle :omz:plugins:ssh-agent      identities                   $SSH_MASTER_KEY
zstyle :omz:plugins:ssh-agent      lazy                         yes

zstyle ':z4h:ssh-agent:' start      yes
zstyle ':z4h:ssh-agent:' extra-args -t 20h


# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
# zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh' '~/.zshrc' '~/.zprofile' '~/.profile'

# Path config
path+=(~/.bin ~/.local/bin $ZDOTDIR/bin)


# Plugins installation
# z4h install ohmyzsh/ohmyzsh || return
z4h install romkatv/archive romkatv/zsh-prompt-benchmark

# z4h load   ohmyzsh/ohmyzsh/plugins/command-not-found  # load a plugin

z4h init || return

setopt glob_dots magic_equal_subst no_multi_os no_local_loops
setopt rm_star_silent rc_quotes glob_star_short

fpath=($Z4H/romkatv/archive $fpath)

# Activate helpers functions
[[ -d $Z4H_FUNCTIONS ]] && fpath=($Z4H_FUNCTIONS $fpath)
autoload -Uz -- zmv archive lsarchive unarchive $Z4H_FUNCTIONS/[^_]*(N:t)


# 
if [[ ! -d "$HISTFOLDER" ]]; then
  mkdir -p "$HISTFOLDER"
fi

export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE

() {
  local hist
  for hist in $HISTFOLDER/zsh_history*~$HISTFILE(N); do
    fc -RI $hist
  done
}

function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }

compdef _directories md
compdef _default     open

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

zstyle    ':z4h:ssh:*' enable           yes
zstyle    ':z4h:ssh:*' ssh-command      command ssh
zstyle    ':z4h:ssh:*' send-extra-files '~/.config/htop/htoprc'
zstyle -e ':z4h:ssh:*' retrieve-history 'reply=($HISTFOLDER/zsh_history.${(%):-%m}:$z4h_ssh_host)'

# Disable some keys
() {
  local key keys=(
    "^B"   "^D"   "^F"   "^N"   "^O"   "^P"   "^Q"   "^S"   "^T"   "^W"
    "^X*"  "^X="  "^X?"  "^XC"  "^XG"  "^Xa"  "^Xc"  "^Xd"  "^Xe"  "^Xg"  "^Xh"  "^Xm"  "^Xn"
    "^Xr"  "^Xs"  "^Xt"  "^Xu"  "^X~"  "^[ "  "^[!"  "^['"  "^[,"  "^[<"  "^[>"  "^[?"
    "^[A"  "^[B"  "^[C"  "^[D"  "^[F"  "^[G"  "^[L"  "^[M"  "^[N"  "^[P"  "^[Q"  "^[S"  "^[T"
    "^[U"  "^[W"  "^[_"  "^[a"  "^[b"  "^[d"  "^[f"  "^[g"  "^[l"  "^[n"  "^[p"  "^[q"  "^[s"
    "^[t"  "^[u"  "^[w"  "^[y"  "^[z"  "^[|"  "^[~"  "^[^I" "^[^J" "^[^_" "^[\"" "^[\$" "^X^B"
    "^X^F" "^X^J" "^X^K" "^X^N" "^X^O" "^X^R" "^X^U" "^X^X" "^[^D" "^[^G")
  for key in $keys; do
    bindkey $key z4h-do-nothing
  done
}

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace    
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace   Ctrl+H
z4h bindkey z4h-accept-line         Enter
z4h bindkey z4h-cd-back             Alt+Left
z4h bindkey z4h-cd-forward          Alt+Right
z4h bindkey z4h-cd-up               Alt+Up
z4h bindkey z4h-fzf-dir-history     Alt+Down
z4h bindkey z4h-exit                Ctrl+D
z4h bindkey z4h-quote-prev-zword    Alt+Q
z4h bindkey copy-prev-shell-word    Alt+C
z4h bindkey undo Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey redo Alt+/             # redo the last undone command line change

function skip-csi-sequence() {
  local key
  while read -sk key && (( $((#key)) < 0x40 || $((#key)) > 0x7E )); do
    # empty body
  done
}

zle -N skip-csi-sequence
bindkey '\e[' skip-csi-sequence

setopt ignore_eof

if (( $+functions[toggle-dotfiles] )); then
  zle -N toggle-dotfiles
  z4h bindkey toggle-dotfiles Ctrl+P
fi

function grep_no_cr() {
  emulate -L zsh -o pipe_fail
  local -a tty base=(grep)
  if [[ ${${:-grep}:c:A:t} != busybox* ]]; then
    base+=(--exclude-dir={.bzr,CVS,.git,.hg,.svn})
    tty+=(--color=auto --line-buffered)
  fi
  if [[ -t 1 ]]; then
    $base $tty "$@" | tr -d "\r"
  else
    $base "$@"
  fi
}
compdef grep_no_cr=grep
alias grep=grep_no_cr

# Alias definitions
alias ls="${aliases[ls]:-ls} -A"
#alias sudo="sudo -Es"
# alias clear="z4h-clear-screen-soft-bottom"
if [[ -n $commands[dircolors] && ${${:-ls}:c:A:t} != busybox* ]]; then
  alias ls="${aliases[ls]:-ls} --group-directories-first"
fi
alias '$'=' '
alias '%'=' '

aliases[=]='noglob arith-eval'

(( $+commands[ip]  )) && alias ip='ip -c'
(( $+commands[tree]  )) && alias tree='tree -a -I .git --dirsfirst'
(( $+commands[rsync] )) && alias rsync='rsync -rz --info=FLIST,COPY,DEL,REMOVE,SKIP,SYMSAFE,MISC,NAME,PROGRESS,STATS'
(( $+commands[exa]   )) && alias exa='exa -ga --group-directories-first --time-style=long-iso --color-scale'

(( $+commands[xclip]   )) && alias pbcopy='xclip -selection clipboard -in'
(( $+commands[xclip]   )) && alias pbpaste='xclip -selection clipboard -out'

(( $+commands[bat]   )) && alias cat='bat -pp --theme=TwoDark --color=always'
(( $+commands[fzf]   )) && alias fzf="fzf --preview='bat -pp --theme=TwoDark --color=always {}'"

if [[ -v commands[xclip] && -n $DISPLAY ]]; then
  function x() xclip -selection clipboard -in
  function v() xclip -selection clipboard -out
  function c() xclip -selection clipboard -in -filter
elif [[ -v commands[base64] && -w $TTY ]]; then
  function x() {
    emulate -L zsh -o pipe_fail
    {
      print -n '\e]52;c;' && base64 | tr -d '\n' && print -n '\a'
    } >$TTY
  }
  function c() {
    emulate -L zsh -o pipe_fail
    local data
    data=$(tee -- $TTY && print x) || return
    data[-1]=
    print -rn -- $data | x
  }
else
  [[ -v functions[x] ]] && unfunction x
  [[ -v functions[v] ]] && unfunction v
  [[ -v functions[c] ]] && unfunction c
fi

if [[ -v functions[x] ]]; then
  function copy-buffer-to-clipboard() print -rn -- "$PREBUFFER$BUFFER" | x
  zle -N copy-buffer-to-clipboard
  bindkey '^S' copy-buffer-to-clipboard
fi

if [[ -x $ZDOTDIR/bin/num-cpus ]]; then
  if (( $+commands[make] )); then
    alias make='make -j "${_my_num_cpus:-${_my_num_cpus::=$($ZDOTDIR/bin/num-cpus)}}"'
  fi
  if (( $+commands[cmake] )); then
    alias cmake='cmake -j "${_my_num_cpus:-${_my_num_cpus::=$($ZDOTDIR/bin/num-cpus)}}"'
  fi
fi

z4h source -c -- $ZDOTDIR/.zshrc-private
z4h compile -- $ZDOTDIR/{.zshenv,.zprofile,.zshrc,.zlogin,.zlogout}
