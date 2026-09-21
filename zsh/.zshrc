# ─── ZINIT BOOTSTRAP ──────────────────────────────────────────
# Auto-clone zinit on a fresh machine instead of assuming it exists.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -d "$ZINIT_HOME" ]] || git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "$ZINIT_HOME/zinit.zsh"

zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ─── PERSISTENT HISTORY ───────────────────────────────────────
# This fixes the "amnesia" between sessions.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS       # Do not store consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS   # Remove previous duplicates from history
setopt HIST_IGNORE_SPACE      # Do not store commands starting with a space
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY          # Share history between open terminals
setopt APPEND_HISTORY         # Append to the file instead of overwriting
setopt INC_APPEND_HISTORY     # Write to history immediately, not on exit

# ─── OH-MY-ZSH LIGHT ──────────────────────────────────────────
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git

# ─── AUTOSUGGESTIONS: configure BEFORE loading the plugin ─────
# color8 = on_surface_variant.dark — subtle gray, does not compete with text
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8,italic'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20    # Do not suggest on very long commands
ZSH_AUTOSUGGEST_USE_ASYNC=true        # Do not block while looking up suggestions

# ─── TURBO PLUGINS ────────────────────────────────────────────
zinit wait'0' lucid for \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-history-substring-search \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-syntax-highlighting

zinit wait'1' lucid for Aloxaf/fzf-tab

# ─── KEYBOARD ─────────────────────────────────────────────────
typeset -g -A key
key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"

bindkey "^[[H" beginning-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[OF" end-of-line

[[ -n "$key[Delete]" ]] && bindkey -- "$key[Delete]" delete-char
[[ -n "$key[Insert]" ]] && bindkey -- "$key[Insert]" overwrite-mode

# History substring search — terminfo first, escape code as fallback
[[ -n "$key[Up]" ]]   && bindkey -- "$key[Up]"   history-substring-search-up
[[ -n "$key[Down]" ]] && bindkey -- "$key[Down]" history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Highlight colors for history-substring-search matches
# color10 = on_primary_container.dark — bright green on background
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=10,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=9,bold'

# ─── FZF-TAB ──────────────────────────────────────────────────
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [ -d $realpath ]; then
     eza -1 --color=always --icons $realpath
  else
     bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath
  fi'

# Mapped to kitty colors:
# bg+:0  = outline.dark (selection background)
# fg+:15 = on_surface.dark (selection text) — maximum contrast
# hl:2   = primary.dark (normal match)
# hl+:10 = on_primary_container.dark (selected match) — bright
# pointer:10, prompt:10 — bright green
# info:11 = on_secondary_container.dark
# spinner:13 = tertiary.dark
# header:8 = on_surface_variant.dark
zstyle ':fzf-tab:*' fzf-flags \
  --color=bg+:0,fg+:15,hl:2,hl+:10,pointer:10,info:11,prompt:10,header:8,spinner:13,marker:13 \
  --bind=tab:accept
zstyle ':fzf-tab:*' switch-group '<' '>'

# ─── SYNTAX HIGHLIGHTING ──────────────────────────────────────
# Color reference (dark kitty theme with contrast 0.3):
# 0  = outline.dark          (dark gray)
# 1  = tertiary.dark         (accent)
# 2  = primary.dark          (base green)
# 3  = secondary.dark        (base yellow/gold)
# 5  = on_tertiary_container (light magenta/accent)
# 6  = on_secondary_container (base cyan)
# 8  = on_surface_variant    (mid gray) ← ideal for subtle things
# 9  = on_tertiary_container (bright accent)
# 10 = on_primary_container  (bright green) ← maximum green contrast
# 11 = on_secondary_container (bright yellow) ← maximum yellow contrast
# 13 = tertiary.dark bright  (bright magenta)
# 14 = secondary.dark bright (bright cyan)
# 15 = on_surface.dark       (white) ← main text

typeset -A ZSH_HIGHLIGHT_STYLES

# ── Commands ─────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[command]='fg=10,bold'           # bright green — most important
ZSH_HIGHLIGHT_STYLES[builtin]='fg=10,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=11,bold'          # bright yellow
ZSH_HIGHLIGHT_STYLES[alias]='fg=14,bold'             # bright cyan
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=10'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=11,underline'   # sudo/env

# ── Strings and arguments ────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=13' # bright magenta
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=13'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=9'    # bright accent
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=9'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=9'
ZSH_HIGHLIGHT_STYLES[assign]='fg=14'                 # bright cyan

# ── Paths ─────────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[path]='fg=15,underline'         # pure white — maximum contrast
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=7,underline'   # mid gray — partial/missing path
ZSH_HIGHLIGHT_STYLES[globbing]='fg=9,bold'           # bright accent — * ? []

# ── Reserved words ────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=11,bold'     # bright yellow — if/for/while
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=3'        # base yellow — ; | &&
ZSH_HIGHLIGHT_STYLES[redirection]='fg=14,bold'       # bright cyan — > >>
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=6'

# ── Errors ────────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'      # tertiary = error red
ZSH_HIGHLIGHT_STYLES[comment]='fg=8,italic'          # subtle gray — # comments

# ── Flags ─────────────────────────────────────────────────────
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=9'    # bright accent — -x
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=9'    # bright accent — --flag

# ─── FUNCTIONS AND ALIASES ────────────────────────────────────
nvim() {
    if [[ "$TERMINAL" == "kitty" || "$TERM" == "xterm-kitty" ]]; then
        kitty @ set-spacing padding=1
        kitty @ set-background-opacity 0.7
        command nvim "$@"
        kitty @ set-spacing padding=2
        kitty @ set-background-opacity 0.5
    else
        command nvim "$@"
    fi
}

# ─── PATH ─────────────────────────────────────────────────────
typeset -U path
path=(
    $HOME/Personal_Scripts/Set_Target
    $HOME/.local/bin
    $HOME/.spicetify
    $path
)
export PATH

# ─── PROMPT & STATUS ──────────────────────────────────────────
command -v fastfetch >/dev/null && fastfetch
eval "$(starship init zsh)"

autoload -Uz compinit && compinit
zinit cdreplay -q
