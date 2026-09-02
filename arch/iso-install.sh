#!/usr/bin/env bash
# ==============================================================================
# Arch Linux — Instalação automatizada a partir da LIVE ISO — GBShadow
# Executa as seções 3 e 4 do INSTALACAO-ARCH.md de uma vez:
#   conecta no Wi-Fi, particiona o SSD 120GB, instala a base, configura
#   locale/rede/bootloader (systemd-boot) e copia os dotfiles do pendrive
#   para /root no novo sistema.
#
# ONDE RODAR: dentro da live ISO (root). O Wi-Fi é conectado sozinho — só
# funciona se o adaptador usado tiver driver NO KERNEL DA ISO (o AIC8800 não
# tem; para ele use USB tethering do celular — guia, seção 2).
#
# ATENÇÃO: credenciais Wi-Fi embutidas abaixo em texto puro (decisão do dono
# do repo). Para trocar: edite WIFI_SSID/WIFI_PASS.
#
# Uso:  bash iso-install.sh [--disk /dev/sdX] [--yes]
#   --disk   força o disco alvo (padrão: detecta o único HD fixo da máquina)
#   --yes    pula a confirmação digitada (NÃO recomendado)
#
# Depois do primeiro boot: siga a seção 5 do guia (arch/install.sh etc.).
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Configuração (edite aqui se mudar algo no guia)
# ------------------------------------------------------------------------------
WIFI_SSID="VIVOFIBRA-E751"
WIFI_PASS="mLTVCK6ew4"

HOSTNAME="arch"
USERNAME="gbshadow"
TIMEZONE="America/Sao_Paulo"
KEYMAP="br-abnt2"
LANG_DEFAULT="pt_BR.UTF-8"

PACSTRAP_PKGS=(
  base linux linux-firmware linux-headers base-devel git dkms
  sudo nano neovim networkmanager intel-ucode zram-generator earlyoom
  e2fsprogs dosfstools ntfs-3g exfatprogs man-db man-pages xdg-user-dirs
)

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}ℹ [INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}✔ [OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠ [AVISO]${NC} $1"; }
log_error() { echo -e "${RED}✖ [ERRO]${NC} $1" >&2; }
die()       { log_error "$1"; exit 1; }
log_header() {
    echo ""
    echo -e "${BLUE}==============================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}==============================================================================${NC}"
}

trap 'log_error "Falhou na linha $LINENO. Se /mnt ficou montado: umount -R /mnt"' ERR

DISK=""
ASSUME_YES=false
while [ $# -gt 0 ]; do
    case "$1" in
        --disk) DISK="${2:-}"; shift 2 ;;
        --yes)  ASSUME_YES=true; shift ;;
        *)      die "Opção desconhecida: $1 (use --disk /dev/sdX, --yes)" ;;
    esac
done

check_internet() {
    ping -c2 -W3 archlinux.org >/dev/null 2>&1 \
        || curl -fsI --max-time 5 https://archlinux.org >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 1. Pré-requisitos: root, UEFI e ferramentas da ISO
# ------------------------------------------------------------------------------
preflight() {
    log_header "1/8 Pré-requisitos"

    [ "$(id -u)" -eq 0 ] || die "Rode como root na live ISO (a ISO já loga como root)."
    [ -d /sys/firmware/efi/efivars ] || die "Sem UEFI. Este script cobre só UEFI (guia, seção 3, nota BIOS legado)."
    for cmd in sgdisk mkfs.fat mkfs.ext4 pacstrap arch-chroot genfstab blkid iwctl; do
        command -v "$cmd" >/dev/null || die "Comando ausente na ISO: $cmd"
    done
}

# ------------------------------------------------------------------------------
# 2. Wi-Fi: conecta na rede fixada; se não achar, pega a mais forte sem "5G"
# ------------------------------------------------------------------------------
wifi_connect() {
    log_header "2/8 Wi-Fi"

    local iface ssid
    iface="$(for d in /sys/class/net/*; do [ -d "$d/wireless" ] && basename "$d" && break; done)"

    if [ -z "$iface" ]; then
        log_warn "Nenhum adaptador Wi-Fi com driver na ISO. Use USB tethering (guia, seção 2):"
        echo "  1) Celular: ative 'Compartilhar internet por USB' com o cabo conectado"
        echo "  2) ip link                            # veja o nome (usb0 / enx...)"
        echo "  3) ip link set <iface> up && dhcpcd <iface>"
        die "Conecte a internet e rode o script de novo."
    fi

    log_info "Adaptador: $iface — escaneando..."
    iwctl station "$iface" scan >/dev/null 2>&1 || true
    sleep 2

    if timeout 30 iwctl --passphrase "$WIFI_PASS" station "$iface" connect "$WIFI_SSID" >/dev/null 2>&1; then
        log_ok "Conectado em '$WIFI_SSID' ($iface)."
    else
        log_warn "Falhou '$WIFI_SSID'. Tentando a rede mais forte SEM '5G' no nome..."
        ssid="$(iwctl station "$iface" get-networks 2>/dev/null | awk '
            /psk|open|8021x|wep/ {
                line=$0
                sub(/^[[:space:]]*[*>]?[[:space:]]*/, "", line)   # marcador
                sub(/[[:space:]]+(psk|open|8021x|wep)[[:space:]]+-?[0-9]+[[:space:]]*$/, "", line)
                if (tolower(line) !~ /5g/) print line
            }' | head -1)"
        [ -n "$ssid" ] || die "Nenhuma rede sem '5G' encontrada. Verifique o roteador ou use tethering."
        timeout 30 iwctl --passphrase "$WIFI_PASS" station "$iface" connect "$ssid" >/dev/null 2>&1 \
            || die "Não conectou nem em '$ssid'. Use USB tethering (guia, seção 2) e rode de novo."
        log_ok "Conectado em '$ssid' ($iface)."
    fi

    sleep 2
    check_internet || die "Wi-Fi OK mas sem internet (DNS/DHCP?). dhcpcd $iface, ou tethering."
    log_ok "Internet OK."
}

# ------------------------------------------------------------------------------
# 3. Disco alvo: o único HD fixo (120GB); pendrive da ISO é ignorado
# ------------------------------------------------------------------------------
detect_disk() {
    log_header "3/8 Disco alvo"

    local live_src live_disk candidates
    # Disco de onde a ISO está rodando (pendrive/loop) — nunca pode ser o alvo
    live_src="$(findmnt -nro SOURCE /run/archiso/bootmnt 2>/dev/null || true)"
    live_disk=""
    if [ -n "$live_src" ]; then
        live_disk="$(lsblk -srno PKNAME "$live_src" 2>/dev/null | head -1 || true)"
        [ -n "$live_disk" ] && live_disk="/dev/$live_disk"
    fi

    candidates="$(lsblk -drno NAME,TYPE,RM | awk -v skip="$live_disk" \
        '$2=="disk" && $3==0 && ("/dev/"$1) != skip {print "/dev/"$1}')"

    if [ -z "$DISK" ]; then
        if [ "$(echo "$candidates" | grep -c .)" -eq 1 ]; then
            DISK="$candidates"
        else
            log_error "Não deu para detectar o disco sozinho. HDs fixos encontrados:"
            echo "$candidates" | sed 's/^/    /'
            [ -n "$live_disk" ] && echo "    (ignorado: $live_disk — mídia da ISO)"
            die "Rode de novo com: bash iso-install.sh --disk /dev/sdX"
        fi
    else
        [ -b "$DISK" ] || die "Disco informado não existe: $DISK"
        echo "$candidates" | grep -qx "$DISK" \
            || die "$DISK não é um HD fixo candidato (removível ou é a mídia da ISO?). Fixos: $candidates"
    fi

    case "$DISK" in
        *nvme*|*mmcblk*) PART_EFI="${DISK}p1"; PART_ROOT="${DISK}p2" ;;
        *)               PART_EFI="${DISK}1";  PART_ROOT="${DISK}2" ;;
    esac

    log_warn "TUDO em $DISK será APAGADO:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$DISK"
}

confirm_destructive() {
    [ "$ASSUME_YES" = true ] && { log_warn "--yes: confirmação pulada."; return; }
    local answer
    read -rp "Digite o caminho COMPLETO do disco (${DISK}) para confirmar o APAGAMENTO: " answer
    [ "$answer" = "$DISK" ] || die "Confirmação não bateu. Abortado — nada foi modificado."
}

# ------------------------------------------------------------------------------
# 4. Particionamento e formatação (guia, seção 3: EFI 1GiB + resto ext4)
# ------------------------------------------------------------------------------
partition_disk() {
    log_header "4/8 Particionando e formatando $DISK"

    sgdisk --zap-all "$DISK"
    sgdisk -n1:0:+1GiB -t1:ef00 -n2:0:0 -t2:8300 "$DISK"
    partprobe "$DISK"
    udevadm settle

    mkfs.fat -F32 "$PART_EFI"
    mkfs.ext4 -F "$PART_ROOT"
    log_ok "p1 = EFI (FAT32, /boot) | p2 = root (ext4, /) — sem swap em disco (ZRAM depois)."
}

# ------------------------------------------------------------------------------
# 5. Instalação da base (guia, seção 4: pacstrap + fstab com noatime)
# ------------------------------------------------------------------------------
install_base() {
    log_header "5/8 pacstrap (base + kernel + DKMS + rede + ZRAM)"

    mount "$PART_ROOT" /mnt
    mkdir -p /mnt/boot
    mount "$PART_EFI" /mnt/boot

    pacstrap -K /mnt "${PACSTRAP_PKGS[@]}"

    genfstab -U /mnt >> /mnt/etc/fstab
    # noatime na raiz (guia: sem escrita de metadado a cada leitura — SSD sem DRAM)
    sed -i '/[[:space:]]\/[[:space:]].*ext4/ s/rw,relatime/rw,noatime/' /mnt/etc/fstab
    grep -q '/ ext4 rw,noatime' /mnt/etc/fstab \
        && log_ok "fstab: root com noatime." \
        || log_warn "noatime NÃO aplicado no fstab — confira: cat /mnt/etc/fstab"
}

# ------------------------------------------------------------------------------
# 6. Configuração dentro do chroot (guia, seção 4: locale, rede, usuários, boot)
# ------------------------------------------------------------------------------
ask_password() {
    local what="$1" p1 p2
    while :; do
        read -rsp "Senha do ${what}: " p1 >&2; echo >&2
        read -rsp "Confirme a senha do ${what}: " p2 >&2; echo >&2
        if [ -z "$p1" ]; then
            log_warn "Senha vazia não. Tente de novo." >&2
        elif [ "$p1" != "$p2" ]; then
            log_warn "Senhas diferentes. Tente de novo." >&2
        else
            printf '%s' "$p1"; return
        fi
    done
}

configure_system() {
    log_header "6/8 Configuração do sistema (chroot)"

    log_info "Defina as senhas (root e $USERNAME):"
    ROOT_PASS="$(ask_password "root")"
    USER_PASS="$(ask_password "$USERNAME")"

    # ZRAM (idêntico ao arch/install.sh) e sysctl — escritos direto no alvo
    tee /mnt/etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    tee /mnt/etc/sysctl.d/99-zram.conf >/dev/null <<'EOF'
vm.swappiness = 100
vm.page-cluster = 0
EOF

    # sudo: grupo wheel com sudo pleno (equivalente ao visudo do guia)
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
    visudo -cf /mnt/etc/sudoers >/dev/null || die "sudoers inválido após editar — verifique /mnt/etc/sudoers"

    cat > /mnt/root/.arch-auto-setup.sh <<CHROOT
set -e
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/; s/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=${LANG_DEFAULT}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}"       > /etc/vconsole.conf
systemctl enable NetworkManager fstrim.timer earlyoom
echo "${HOSTNAME}" > /etc/hostname
id -u ${USERNAME} >/dev/null 2>&1 || useradd -m -G wheel ${USERNAME}
su - ${USERNAME} -c "xdg-user-dirs-update 2>/dev/null || true; mkdir -p ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Music ~/Desktop ~/Templates ~/Public" 2>/dev/null || true
CHROOT
    arch-chroot /mnt bash /root/.arch-auto-setup.sh
    rm -f /mnt/root/.arch-auto-setup.sh

    printf 'root:%s\n' "$ROOT_PASS" | arch-chroot /mnt chpasswd >/dev/null
    printf '%s:%s\n' "$USERNAME" "$USER_PASS" | arch-chroot /mnt chpasswd >/dev/null
    unset ROOT_PASS USER_PASS

    # Bootloader: systemd-boot, ESP em /boot (guia, seção 4)
    arch-chroot /mnt bootctl install
    mkdir -p /mnt/boot/loader/entries
    tee /mnt/boot/loader/loader.conf >/dev/null <<'EOF'
default arch
timeout 3
EOF
    local root_partuuid
    root_partuuid="$(blkid -s PARTUUID -o value "$PART_ROOT")"
    cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=${root_partuuid} rw rootfstype=ext4
EOF
    log_ok "Sistema configurado (locale $LANG_DEFAULT, teclado $KEYMAP, systemd-boot)."
}

# ------------------------------------------------------------------------------
# 7. Copiar os dotfiles do pendrive para /root no novo sistema (guia, seção 5.1)
# ------------------------------------------------------------------------------
copy_dotfiles() {
    log_header "7/8 Dotfiles do pendrive → /mnt/root/dotfiles"

    local tmp part src found=0
    tmp="$(mktemp -d)"
    while read -r name _; do
        part="/dev/$name"
        echo "$name" | grep -q "^$(basename "$DISK")" && continue   # pula o disco alvo
        mount -o ro "$part" "$tmp" 2>/dev/null || continue

        src=""
        [ -f "$tmp/dotfiles/arch/install.sh" ] && src="$tmp/dotfiles"
        [ -z "$src" ] && [ -f "$tmp/arch/install.sh" ] && src="$tmp"

        if [ -n "$src" ]; then
            log_info "Dotfiles encontrados em $part — copiando..."
            cp -a "$src" /mnt/root/dotfiles
            log_ok "Copiado para /root/dotfiles (mova para ~/dotfiles no primeiro boot)."
            found=1
        fi
        umount "$tmp"
        [ "$found" = 1 ] && break
    done < <(lsblk -lrno NAME,TYPE | awk '$2=="part"')

    rmdir "$tmp"
    [ "$found" = 0 ] && log_warn "Pendrive com dotfiles não encontrado. Copie depois à mão (guia, seção 5.1)."
}

# ------------------------------------------------------------------------------
# 8. Finalização
# ------------------------------------------------------------------------------
finish() {
    log_header "8/8 Concluído"

    umount -R /mnt
    log_ok "Instalação finalizada: Arch em $DISK (UEFI, systemd-boot, ZRAM, noatime)."
    echo ""
    echo "Próximos passos (guia, seção 5):"
    echo "  1) reboot (remova o pendrive)"
    echo "  2) login gbshadow → sudo mv /root/dotfiles /home/gbshadow/ && sudo chown -R gbshadow: ~/dotfiles"
    echo "     (se os dotfiles NÃO foram copiados, volte pelo pendrive — seção 5.1)"
    echo "  3) cd ~/dotfiles/arch && ./install.sh --wifi   # base + driver AIC8800"
    echo "  4) ./apps.sh && ./dev.sh"
    local answer
    read -rp "Reiniciar agora? [s/N] " answer
    case "$answer" in
        s|S) reboot ;;
        *)   echo "Ok. /mnt já foi desmontado — pode desligar ou reiniciar quando quiser." ;;
    esac
}

preflight
wifi_connect
detect_disk
confirm_destructive
partition_disk
install_base
configure_system
copy_dotfiles
finish
