# Keep history search local and use the installed fzf key bindings.
if [[ -o interactive ]] && (( $+commands[fzf] )) && [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
    export FZF_CTRL_R_OPTS="--height=45% --layout=reverse --border=rounded --border-label=' Command history ' --prompt='Search > ' --info=inline --color=border:blue,label:cyan,hl:magenta,hl+:magenta --bind=ctrl-y:ignore"
    FZF_CTRL_T_COMMAND='' FZF_ALT_C_COMMAND='' source /usr/share/fzf/key-bindings.zsh
fi
