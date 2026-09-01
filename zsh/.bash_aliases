# YouTube / MPV Playback Helpers
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
