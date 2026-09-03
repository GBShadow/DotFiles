# YouTube / MPV Playback Helpers
export MPV_YT_QUALITY="480"

setres() {
    export MPV_YT_QUALITY="${1:-480}"
    echo "Qualidade padrão do YouTube definida para: ${MPV_YT_QUALITY}p"
}

playv() {
    if [ -z "$1" ]; then
        echo "Uso: playv <url> [opções do mpv]"
        return 1
    fi
    local url="$1"
    shift
    mpv --ytdl-format="bestvideo[height<=${MPV_YT_QUALITY}][vcodec^=avc1]+bestaudio/bestvideo[height<=${MPV_YT_QUALITY}][vcodec!*=av01]+bestaudio/best[height<=${MPV_YT_QUALITY}]" "$@" "$url"
}

playa() {
    if [ -z "$1" ]; then
        echo "Uso: playa <url> [opções do mpv]"
        return 1
    fi
    local url="$1"
    shift
    mpv --no-video "$@" "$url"
}

playpl() {
    if [ -z "$1" ]; then
        echo "Uso: playpl <url> [opções do mpv]"
        return 1
    fi
    local url="$1"
    shift
    mpv --ytdl-raw-options=yes-playlist= --ytdl-format="bestvideo[height<=${MPV_YT_QUALITY}][vcodec^=avc1]+bestaudio/bestvideo[height<=${MPV_YT_QUALITY}][vcodec!*=av01]+bestaudio/best[height<=${MPV_YT_QUALITY}]" "$@" "$url"
}

playpla() {
    if [ -z "$1" ]; then
        echo "Uso: playpla <url> [opções do mpv]"
        return 1
    fi
    local url="$1"
    shift
    mpv --no-video --ytdl-raw-options=yes-playlist= "$@" "$url"
}
playhelp() {
    cat << 'EOF'
======================================================
           🎵 Comandos de Reprodução (MPV/YT)         
======================================================
  playv / plv <url>      : Toca vídeo individual (vídeo + áudio)
  playa / pla <url>      : Toca vídeo individual (apenas áudio)
  playpl / plpl <url>    : Toca playlist inteira (vídeo + áudio)
  playpla / plpla <url>  : Toca playlist inteira (apenas áudio)
  mpvv / mpva / mpvpl    : Atalhos alternativos com prefixo mpv
  setres <altura>        : Define qualidade máxima (ex: setres 720, setres 480)
  playhelp / playcmds    : Exibe esta lista de comandos

⌨️  Atalhos no teclado durante reprodução:
  > / <            : Próxima / Anterior (em playlists)
  Espaço / p       : Pausar / Continuar
  9 / 0            : Diminuir / Aumentar volume
  q                : Fechar / Parar
======================================================
EOF
}
alias playcmds='playhelp'

# Aliases curtos
alias plv='playv'
alias pla='playa'
alias plpl='playpl'
alias plpla='playpla'

# Aliases com prefixo mpv
alias mpvv='playv'
alias mpva='playa'
alias mpvpl='playpl'
alias mpvpla='playpla'
alias mpvh='playhelp'

# Cópia de arquivos com progresso total, taxa de transferência e tempo estimado
alias rs='rsync -ah --info=progress2 --no-inc-recursive'

# Navegação e visualização de arquivos
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias hd-space='df -h -x tmpfs -x devtmpfs'

# Notificação de término de comandos
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Emuladores com Game Mode (desativa picom e trava CPU em performance)
alias psx='game-run.sh duckstation'
alias nds='game-run.sh melonDS'
alias duckstation='game-run.sh duckstation'
alias melonds='game-run.sh melonDS'
