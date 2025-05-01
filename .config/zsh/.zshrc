# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.

# --- Basic Zsh Options ---
# Enable globbing hidden files (like .git)
setopt glob_dots
# Treat '=' as 'command' when it's the first word
setopt magic_equal_subst
# Disable multi_os feature (usually not needed)
setopt no_multi_os
# Disable local loops (usually not needed)
setopt no_local_loops
# Suppress confirmation for `rm *`
setopt rm_star_silent
# Enable single quotes to preserve literal values
setopt rc_quotes
# Enable short globstar (**)
setopt glob_star_short
# Do not write a duplicate event to the history file.
setopt HIST_SAVE_NO_DUPS
# Don't exit on EOF (Ctrl+D) unless the line is empty
setopt ignore_eof

# --- History Configuration ---
# Define the history file location
# HISTFILE is typically set in .zshenv, but ensure HISTFOLDER exists
if [[ -z "$HISTFOLDER" ]]; then
  # Default to ~/.zsh_history if not set
  HISTFOLDER="$HOME/.zsh_history.d"
fi
if [[ ! -d "$HISTFOLDER" ]]; then
  mkdir -p "$HISTFOLDER"
fi
# Set history size and save history size
export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE

# Load history from multiple files in HISTFOLDER (common z4h pattern)
() {
  local hist
  # Load all history files except the current one
  for hist in $HISTFOLDER/zsh_history*~$HISTFILE(N); do
    fc -R $hist
  done
}

# --- Path Configuration ---
# Add common user binary directories to PATH
path+=(~/.bin ~/.local/bin $ZDOTDIR/bin)

# --- z4h Initialization and Plugin Management ---
# Install z4h plugins (if not already installed)
# z4h install sunlei/zsh-ssh || return # Example commented out plugin
z4h install romkatv/archive romkatv/zsh-prompt-benchmark

# Initialize z4h and its plugins. This must be called after installing plugins.
# It also sets up fpath for plugin functions.
z4h init || return

# Add specific plugin function directories to fpath if needed (z4h init might handle this)
# fpath=($Z4H/romkatv/archive $fpath) # Example, likely handled by z4h init

# Activate helpers functions provided by z4h or plugins
# This autoloads all functions in $Z4H_FUNCTIONS that don't start with '_'
[[ -d $Z4H_FUNCTIONS ]] && fpath=($Z4H_FUNCTIONS $fpath)
autoload -Uz -- zmv archive lsarchive unarchive $Z4H_FUNCTIONS/[^_]*(N:t)

# --- z4h Configuration (zstyle) ---

# General z4h settings
zstyle ':z4h:' auto-update no           # Disable automatic updates
zstyle ':z4h:' auto-update-days 28      # Check for updates every 28 days
zstyle ':z4h:*' channel dev             # Use the 'dev' channel for most plugins
zstyle ':z4h:zsh-syntax-highlighting' channel stable # Use 'stable' for syntax highlighting

# Autosuggestion configuration
zstyle ':z4h:autosuggestions' forward-char partial-accept # Accept suggestion partially when moving forward
zstyle ':z4h:autosuggestions' end-of-line partial-accept   # Accept suggestion partially at end of line

# FZF integration configuration
zstyle ':z4h:fzf-complete' recurse-dirs no # Don't recurse into subdirectories for fzf completion
zstyle ':z4h:fzf-history' fzf-flags --color='pointer:#7842f5' # Customize fzf history color
# zstyle ':z4h:fzf-dir-history' fzf-bindings tab:repeat # Example commented out binding
# zstyle ':z4h:fzf-complete' fzf-bindings tab:repeat   # Example commented out binding
# zstyle ':z4h:cd-down' fzf-bindings tab:repeat        # Example commented out binding

# Terminal Title configuration (especially for SSH sessions)
# Set title format for SSH sessions before command execution
zstyle ':z4h:term-title:ssh' precmd ${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'
# Set title format for SSH sessions during command execution
zstyle ':z4h:term-title:ssh' preexec ${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
# Example commented out title formats including username
# zstyle ':z4h:term-title:ssh' precmd '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'
# zstyle ':z4h:term-title:ssh' preexec '%n@'${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'

# Shell behavior configuration
zstyle ':z4h:command-not-found' to-file "$TTY" # Send command not found suggestions to TTY
zstyle ':z4h:' term-shell-integration yes      # Enable terminal shell integration
zstyle ':z4h:' propagate-cwd yes               # Propagate current working directory
zstyle ':z4h:' prompt-height 4                 # Set prompt height
zstyle ':z4h:' prompt-at-bottom yes            # Show prompt at the bottom of the screen

# SSH Agent configuration
if [[ -z "$Z4H_SSH" ]]; then
  # Start ssh-agent if not in an SSH session
  zstyle ':z4h:ssh-agent:' start yes
else
  # Do not start ssh-agent in a remote SSH session to avoid issues
  zstyle ':z4h:ssh-agent:' start no
fi
# Add extra arguments to ssh-agent (e.g., key lifetime)
zstyle ':z4h:ssh-agent:' extra-args -t 20h

# SSH specific settings
zstyle ':z4h:ssh:*' enable yes # Enable z4h SSH features
zstyle ':z4h:ssh:*' ssh-command command ssh # Use the standard ssh command
# Retrieve history from remote host on SSH connection
zstyle -e ':z4h:ssh:*' retrieve-history 'reply=($HISTFOLDER/zsh_history.${(%):-%m}:$z4h_ssh_host)'
# Send these files over to the remote host when connecting over SSH to the enabled hosts.
# zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh' '~/.zshrc' '~/.zprofile' '~/.profile'

# Direnv configuration
zstyle ':z4h:direnv' enable 'yes' # Enable direnv integration
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# --- Completion Configuration ---
# Disable sorting for completion results
zstyle ':completion:*' sort false
# List directories first in ls completion
zstyle ':completion:*:ls:*' list-dirs-first true

# Function to filter SSH hosts from a custom file
filter_hosts() {
  # Read hosts from ~/.ssh/config.d/hosts.ssh, filter lines starting with 'Host ',
  # extract the host name, and store in the reply array.
  reply=(${(@)${(@M)${(f)"$(cat ~/.ssh/config.d/hosts.ssh)"}:#*Host *}#*Host })
}

# Define tag order for ssh/scp/rdp completion
zstyle ':completion:*:ssh:argument-1:' tag-order hosts users
zstyle ':completion:*:scp:argument-rest:' tag-order hosts files users
# Use the filter_hosts function for hosts completion in ssh/scp/rdp
zstyle -e ':completion:*:(ssh|scp|rdp):*:hosts' hosts filter_hosts

# --- ZLE (Zsh Line Editor) Configuration ---

# Search configuration
zstyle ':zle:up-line-or-beginning-search' leave-cursor no # Don't leave cursor at beginning of line after search
zstyle ':zle:down-line-or-beginning-search' leave-cursor no # Don't leave cursor at beginning of line after search

# Disable some default key bindings that might conflict or are not desired
() {
  local key keys=(
    "^B"   "^D"   "^F"   "^N"   "^O"   "^P"   "^Q"   "^S"   "^T"   "^W"
    "^X*"  "^X="  "^X?"  "^XC"  "^XG"  "^Xa"  "^Xc"  "^Xd"  "^Xe"  "^Xg"  "^Xh"  "^Xm"  "^Xn"
    "^Xr"  "^Xs"  "^Xt"  "^Xu"  "^X~"  "^[ "  "^[!"  "^['"  "^[,"  "^[<"  "^[>"  "^[?"
    "^[A"  "^[B"  "^[C"  "^[D"  "^[F"  "^[G"  "^[L"  "^[M"  "^[N"  "^[P"  "^[Q"  "^[S"  "^[T"
    "^[U"  "^[W"  "^[_"  "^[a"  "^[b"  "^[d"  "^[f"  "^[g"  "^[l"  "^[n"  "^[p"  "^[q"  "^[s"
    "^[t"  "^[u"  "^[w"  "^[y"  "^[z"  "^[|"  "^[~"  "^[^I" "^[^J" "^[^_" "^[\"" "^[\$" "^X^B"
    "^X^F" "^X^J" "^X^K" "^X^N" "^X^O" "^X^R" "^X^U" "^X^X" "^[^D" "^[^")
  for key in $keys; do
    bindkey $key z4h-do-nothing
  done
}

# Define custom key bindings using z4h helper
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace
z4h bindkey z4h-accept-line         Enter
z4h bindkey z4h-cd-back             Alt+Left
z4h bindkey z4h-cd-forward          Alt+Right
z4h bindkey z4h-cd-up               Alt+Up
z4h bindkey z4h-fzf-dir-history     Alt+Down
z4h bindkey z4h-exit                Ctrl+D
z4h bindkey push-input              Ctrl+Q             # Push current input onto the buffer stack
z4h bindkey copy-prev-shell-word    Alt+C              # Copy the last word of the previous command
z4h bindkey undo Ctrl+/ Shift+Tab                      # Undo the last command line change
z4h bindkey redo Alt+/                                 # Redo the last undone command line change
# z4h bindkey run-help Ctrl+H                          # Example commented out binding

# Bindings for sudo history commands
zle -N sudo-previous # Edit the previous command prepended with sudo
zle -N sudo-escalate # Edit the current command prepended with sudo
z4h bindkey sudo-previous Ctrl+E

# Binding for toggle-dotfiles function (if it exists)
if (( $+functions[toggle-dotfiles] )); then
  zle -N toggle-dotfiles
  z4h bindkey toggle-dotfiles Ctrl+P
fi

# Function to skip CSI sequences (often used with terminal passthrough)
function skip-csi-sequence() {
  local key
  # Read keys until a printable ASCII character is received
  while read -sk key && (( $((#key)) < 0x40 || $((#key)) > 0x7E )); do
    # empty body
  done
}
# Bind the skip-csi-sequence function to the start of a CSI sequence
zle -N skip-csi-sequence
bindkey '\e[' skip-csi-sequence

# --- Clipboard Functions (x, v, c) ---
# Define functions for interacting with the system clipboard
if [[ -v commands[xclip] && -n $DISPLAY ]]; then
  # Use xclip if available and DISPLAY is set (X server is running)
  function x() xclip -selection clipboard -in # Copy stdin to clipboard
  function v() xclip -selection clipboard -out # Paste from clipboard to stdout
  function c() xclip -selection clipboard -in -filter # Copy stdin to clipboard, filtering control chars
elif [[ -v commands[base64] && -w $TTY ]]; then
  # Fallback using base64 and OSC 52 sequence if xclip/DISPLAY not available but TTY is writable
  function x() {
    emulate -L zsh -o pipe_fail
    # Send OSC 52 sequence to copy to clipboard
    {
      print -n '\e]52;c;' && base64 | tr -d '\n' && print -n '\a'
    } >$TTY
  }
  function c() {
    emulate -L zsh -o pipe_fail
    local data
    # Read data from stdin via tee, then send to x function
    data=$(tee -- $TTY && print x) || return
    data[-1]= # Remove the trailing 'x' from the tee output
    print -rn -- $data | x
  }
  # Note: A 'v' function using OSC 52 to paste is more complex and often not reliable.
  # It's omitted here, relying on terminal paste functionality instead.
else
  # If neither xclip/DISPLAY nor base64/TTY fallback is possible, undefine functions
  [[ -v functions[x] ]] && unfunction x
  [[ -v functions[v] ]] && unfunction v
  [[ -v functions[c] ]] && unfunction c
fi

# Bind Ctrl+S to copy the current buffer to clipboard if 'x' function is defined
if [[ -v functions[x] ]]; then
  function copy-buffer-to-clipboard() print -rn -- "$PREBUFFER$BUFFER" | x
  zle -N copy-buffer-to-clipboard
  bindkey '^S' copy-buffer-to-clipboard
fi

# --- Utility Functions ---

# Function to grep without carriage returns, with color and exclude dirs
function grep_no_cr() {
  emulate -L zsh -o pipe_fail
  local -a tty base=(grep)
  # Add exclude-dir and color/line-buffered options if not using busybox grep
  if [[ ${${:-grep}:c:A:t} != busybox* ]]; then
    base+=(--exclude-dir={.bzr,CVS,.git,.hg,.svn})
    tty+=(--color=auto --line-buffered)
  fi
  # Use tr -d "\r" only if stdout is a TTY
  if [[ -t 1 ]]; then
    $base $tty "$@" | tr -d "\r"
  else
    $base "$@"
  fi
}
# Set completion for grep_no_cr to use grep's completion
compdef grep_no_cr=grep

# Function to create a directory and change into it
function md() {
  [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"
}
# Set completion for md to complete directories
compdef _directories md

# Set default completion for the 'open' command
compdef _default open

# --- Aliases ---

# Alias definitions
alias grep=grep_no_cr # Use the custom grep function by default
alias clear="z4h-clear-screen-soft-bottom" # Use z4h soft clear

# Conditional aliases based on command availability
# Alias ls to add --group-directories-first if dircolors is available and ls is not busybox
if [[ -n $commands[dircolors] && ${${:-ls}:c:A:t} != busybox* ]]; then
  alias ls="${aliases[ls]:-ls} --group-directories-first"
fi

# Alias ip to add color output if stdout is a TTY
ip() {
  if [ -t 1 ]; then
    # stdout is connected to TTY
    command ip -c "$@"
  else
    # if pipe or redirection
    command ip "$@"
  fi
}

# Aliases for common tools with preferred options
(( $+commands[tree]  )) && alias tree='tree -a -I .git --dirsfirst'
(( $+commands[rsync] )) && alias rsync='rsync -rz --info=FLIST,COPY,DEL,REMOVE,SKIP,SYMSAFE,MISC,NAME,PROGRESS,STATS'
(( $+commands[exa]   )) && alias exa='exa -ga --group-directories-first --time-style=long-iso --color-scale'
(( $+commands[bat]   )) && alias cat='bat -pp --theme=TwoDark --color=auto'
(( $+commands[lsd]   )) && alias ls='lsd' # Override previous ls alias if lsd is available
(( $+commands[fzf]   )) && alias fzf="fzf --preview='bat -pp --theme=TwoDark --color=always {}'"

# Clipboard aliases using xclip (if available)
(( $+commands[xclip]   )) && alias pbcopy='xclip -selection clipboard -in'
(( $+commands[xclip]   )) && alias pbpaste='xclip -selection clipboard -out'

# Aliases for make/cmake using num-cpus (if available)
if [[ -x $ZDOTDIR/bin/num-cpus ]]; then
  # Cache the number of CPUs
  _my_num_cpus=$($ZDOTDIR/bin/num-cpus)
  if (( $+commands[make] )); then
    alias make="make -j $_my_num_cpus"
  fi
  if (( $+commands[cmake] )); then
    alias cmake="cmake -j $_my_num_cpus"
  fi
fi

# Example commented out aliases
# alias '$'=' '
# alias '%'=' '
# aliases[=]='noglob arith-eval' # Alias '=' to noglob arith-eval

# --- Named Directories ---
# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# --- Sourcing External Files ---
# Source private zsh configuration (e.g., sensitive variables, overrides)
z4h source -c -- $ZDOTDIR/.zshrc-private

# Source Powerlevel10k configuration
# This must be sourced after z4h init and potentially other configurations
source $ZDOTDIR/.p10k.zsh

# Source Google Cloud SDK setup scripts if they exist
# These typically update PATH and set up completion
if [ -f "$HOME/.apps/.google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/.apps/.google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/.apps/.google-cloud-sdk/completion.zsh.inc" ]; then
  . "$HOME/.apps/.google-cloud-sdk/completion.zsh.inc"
fi

# Source Warp CLI completions if available
(( $+commands[warp-cli]   )) && eval "$(warp-cli generate-completions zsh)"

# --- Compilation ---
# Compile zsh files for faster startup (optional, can also be done by install script)
# This should generally be done after all sourcing and setup is complete.
z4h compile -- $ZDOTDIR/{.zshenv,.zprofile,.zshrc,.zlogin,.zlogout}
