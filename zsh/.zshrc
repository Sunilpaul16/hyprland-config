# --------------------------
# Instant prompt for Powerlevel10k
# --------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --------------------------
# Zsh history settings
# --------------------------
zsh_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$zsh_state_dir" "$zsh_cache_dir"

# One-time migration from the old config-local state path.
if [[ -f "$ZDOTDIR/.zsh_history" && ! -e "$zsh_state_dir/history" ]]; then
    mv -- "$ZDOTDIR/.zsh_history" "$zsh_state_dir/history"
fi

HISTFILE="$zsh_state_dir/history"
HISTSIZE=1000
SAVEHIST=1000

setopt sharehistory
setopt appendhistory
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

# --------------------------
# Oh My Zsh
# --------------------------
export ZSH="$HOME/.config/zsh/oh-my-zsh"
ZSH_COMPDUMP="$zsh_cache_dir/zcompdump-$ZSH_VERSION"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Fuzzy command history (Ctrl+R).
[[ -r "$ZDOTDIR/fuzzy-history.zsh" ]] && source "$ZDOTDIR/fuzzy-history.zsh"

# --------------------------
# Powerlevel10k config
# --------------------------
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# --------------------------
# Custom function
# --------------------------
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# --------------------------
# Other options
# --------------------------
setopt PROMPT_SP
export PATH="$HOME/.local/bin:$PATH"
