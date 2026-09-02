#!/usr/bin/env bash
# ==============================================================================
# Arch Linux — Configuração pós-base (Usuários, Senhas, Bootloader, Dotfiles)
# GBShadow
#
# Executa a partir da criação de usuários e configuração do sistema:
#   - Solicita senhas de root e do usuário (gbshadow)
#   - Configura ZRAM, sysctl e permissões sudo (wheel)
#   - Ajusta fuso horário, relógio, locale (pt_BR.UTF-8), teclado (br-abnt2)
#   - Habilita serviços essenciais (NetworkManager, fstrim.timer, earlyoom)
#   - Cria o usuário e aplica as senhas via chroot
#   - Instala e configura o bootloader (systemd-boot)
#   - Copia os dotfiles do pendrive para /root/dotfiles
#   - Desmonta /mnt e finaliza a instalação
#
# ONDE RODAR: na live ISO, após o particionamento e instalação da base (pacstrap)
# com o sistema montado em /mnt (e EFI em /mnt/boot).
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Configuração
# ------------------------------------------------------------------------------
HOSTNAME="arch"
USERNAME="gbshadow"
TIMEZONE="America/Sao_Paulo"
KEYMAP="br-abnt2"
LANG_DEFAULT="pt_BR.UTF-8"

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

preflight() {
    log_header "1/4 Pré-requisitos"

    [ "$(id -u)" -eq 0 ] || die "Rode como root na live ISO."
    [ -d /sys/firmware/efi/efivars ] || die "Sem UEFI. Este script cobre só UEFI."

    for cmd in arch-chroot blkid bootctl; do
        command -v "$cmd" >/dev/null || die "Comando ausente na ISO: $cmd"
    done

    mountpoint -q /mnt || die "/mnt não está montado. Monte a partição root em /mnt e a partição EFI em /mnt/boot."
    [ -d /mnt/boot ] || die "/mnt/boot não existe. Monte a partição EFI em /mnt/boot."

    PART_ROOT="$(findmnt -nro SOURCE /mnt 2>/dev/null || true)"
    [ -n "$PART_ROOT" ] || die "Não foi possível identificar o dispositivo montado em /mnt."

    DISK="$(lsblk -srno PKNAME "$PART_ROOT" 2>/dev/null | head -1 || true)"
    [ -n "$DISK" ] && DISK="/dev/$DISK" || DISK="$PART_ROOT"

    log_ok "Root detectado em: $PART_ROOT (Disco: $DISK)"
}

# ------------------------------------------------------------------------------
# 2. Configuração do sistema e usuários (chroot)
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
    log_header "2/4 Configuração do sistema e usuários (chroot)"

    log_info "Defina as senhas (root e $USERNAME):"
    ROOT_PASS="$(ask_password "root")"
    USER_PASS="$(ask_password "$USERNAME")"

    # ZRAM e sysctl — escritos direto no alvo
    tee /mnt/etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    tee /mnt/etc/sysctl.d/99-zram.conf >/dev/null <<'EOF'
vm.swappiness = 100
vm.page-cluster = 0
EOF

    # sudo: grupo wheel com sudo pleno
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
CHROOT
    arch-chroot /mnt bash /root/.arch-auto-setup.sh
    rm -f /mnt/root/.arch-auto-setup.sh

    printf 'root:%s\n' "$ROOT_PASS" | arch-chroot /mnt chpasswd >/dev/null
    printf '%s:%s\n' "$USERNAME" "$USER_PASS" | arch-chroot /mnt chpasswd >/dev/null
    unset ROOT_PASS USER_PASS

    # Bootloader: systemd-boot, ESP em /boot
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
# 3. Copiar os dotfiles do pendrive para /root no novo sistema
# ------------------------------------------------------------------------------
copy_dotfiles() {
    log_header "3/4 Dotfiles do pendrive → /mnt/root/dotfiles"

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
# 4. Finalização
# ------------------------------------------------------------------------------
finish() {
    log_header "4/4 Concluído"

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
configure_system
copy_dotfiles
finish
