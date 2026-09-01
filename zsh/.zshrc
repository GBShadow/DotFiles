# ==============================================================================
# Environment & PATH
# ==============================================================================
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

if [ -d "$HOME/.opencode/bin" ]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi

# ==============================================================================
# Oh My Zsh Configuration
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Prompt theme is managed by Starship
ZSH_THEME=""

# Oh My Zsh Plugins (Suggested helper plugins)
plugins=(
    git
    sudo
    colored-man-pages
    extract
    history
)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# ==============================================================================
# Zinit Plugin Manager
# ==============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Plugins requested by user
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# Suggested Zinit plugins
zinit light zsh-users/zsh-history-substring-search

# History substring search keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Zsh Completion initialization
autoload -Uz compinit && compinit -C
zinit cdreplay -q

# ==============================================================================
# Shell Options & History
# ==============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# ==============================================================================
# Aliases
# ==============================================================================
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

if [ -f "$HOME/.bash_aliases" ]; then
    source "$HOME/.bash_aliases"
fi

# ==============================================================================
# Starship Prompt Initialization
# ==============================================================================
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ==============================================================================
# YouTube / MPV Playback Helpers
# ==============================================================================
export MPV_YT_QUALITY="480"

setres() {
    export MPV_YT_QUALITY="${1:-480}"
    echo "Qualidade padrão do YouTube definida para: ${MPV_YT_QUALITY}p"
}

playv() {
    local url="$1"
    shift
    mpv --ytdl-format="bestvideo[height<=${MPV_YT_QUALITY}]+bestaudio/best[height<=${MPV_YT_QUALITY}]" "$@" "$url"
}

playa() {
    local url="$1"
    shift
    mpv --no-video "$@" "$url"
}

playpl() {
    local url="$1"
    shift
    mpv --ytdl-raw-options=yes-playlist= --ytdl-format="bestvideo[height<=${MPV_YT_QUALITY}]+bestaudio/best[height<=${MPV_YT_QUALITY}]" "$@" "$url"
}

playpla() {
    local url="$1"
    shift
    mpv --no-video --ytdl-raw-options=yes-playlist= "$@" "$url"
}

playhelp() {
    cat << 'EOF'
======================================================
           🎵 Comandos de Reprodução (MPV/YT)         
======================================================
  playv <url>      : Toca vídeo individual (vídeo + áudio)
  playa <url>      : Toca vídeo individual (apenas áudio)
  playpl <url>     : Toca playlist inteira (vídeo + áudio)
  playpla <url>    : Toca playlist inteira (apenas áudio)
  setres <altura>  : Define qualidade máxima (ex: setres 720, setres 480)
  playhelp         : Exibe esta lista de comandos

⌨️  Atalhos no teclado durante reprodução:
  > / <            : Próxima / Anterior (em playlists)
  Espaço / p       : Pausar / Continuar
  9 / 0            : Diminuir / Aumentar volume
  q                : Fechar / Parar
======================================================
EOF
}
alias playcmds='playhelp'
