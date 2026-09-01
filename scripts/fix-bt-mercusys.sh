#!/usr/bin/env bash

#############################################################################
# Mercusys Bluetooth Adapter — btusb Patcher (RTL8761BUV)
#
# O dongle Mercusys (VID 2c4e, PID 0115) usa o chip Realtek RTL8761BUV,
# mas o kernel Linux NÃO inclui esse VID:PID na tabela do driver btusb.
# Sem essa entrada, o btusb não carrega o firmware (rtl8761bu_fw.bin) e o
# rádio BT fica morto — scan não encontra nenhum dispositivo.
#
# Este script:
#   1. Baixa os headers corretos do kernel (via snapshot.debian.org se preciso)
#   2. Baixa o btusb.c do kernel.org e adiciona o Mercusys na tabela Realtek
#   3. Compila e instala o módulo patcheado
#   4. Desbloqueia rfkill e ativa o adaptador
#
# Suporta:
#   - Debian Trixie / MiniOS com kernel 6.12 ou superior
#   - Kernels que já têm suporte nativo: detecta o firmware e não recompila
#   - Reexecução segura (idempotente)
#
# Uso:
#   sudo ./fix-bt-mercusys.sh
#############################################################################

set -euo pipefail

# ── Visual ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step()    { echo -e "\n${CYAN}${BOLD}==> ${NC}${BOLD}$1${NC}"; }

# ── Constantes ──────────────────────────────────────────────────────────────
MERCUSYS_VID="2c4e"
MERCUSYS_PID="0115"
BT_ALIAS="Mercusys Bluetooth"
KVER=$(uname -r)
KVER_BASE="${KVER%%[-+]*}"          # ex: 6.12.57
KVER_MAJOR="${KVER_BASE%.*}"        # ex: 6.12
BUILD_DIR="/tmp/btusb-mercusys-patch"
BTUSB_URL="https://raw.githubusercontent.com/torvalds/linux/v${KVER_MAJOR}/drivers/bluetooth/btusb.c"
BT_HEADERS=(btintel.h btrtl.h btbcm.h btmtk.h)

# ── Checagens ───────────────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Execute como root: sudo $0"
        exit 1
    fi
}

check_device_present() {
    if ! lsusb | grep -qi "${MERCUSYS_VID}:${MERCUSYS_PID}"; then
        log_error "Dongle Mercusys (${MERCUSYS_VID}:${MERCUSYS_PID}) não encontrado no USB."
        log_error "Conecte o adaptador e tente novamente."
        exit 1
    fi
    log_success "Dongle Mercusys detectado no USB."
}

check_already_working() {
    # Logs antigos não bastam: confirme que o controlador Mercusys ainda existe.
    if dmesg 2>/dev/null | grep -q "RTL:.*loading.*rtl8761bu"; then
        local hci
        local mercusys_present=false
        hci=$(dmesg | grep -oP 'hci\d+(?=: RTL:.*rtl8761bu)' | tail -1)

        for hci_dir in /sys/class/bluetooth/hci*/; do
            local dev_path
            local product
            dev_path=$(readlink -f "$hci_dir/device" 2>/dev/null) || continue
            product=$(cat "$dev_path/../product" 2>/dev/null) || continue
            if [[ "$product" == *MERCUSYS* ]] || [[ "$product" == *Mercusys* ]] || [[ "$product" == *mercusys* ]]; then
                mercusys_present=true
                break
            fi
        done

        if [[ -n "$hci" && "$mercusys_present" == true ]]; then
            log_success "Firmware Realtek já está sendo carregado para $hci."
            log_info "O patch já está aplicado. Nada a fazer."

            # Garantir que está UP
            ensure_adapter_up
            exit 0
        fi
    fi
}

check_btusb_needs_patch() {
    # Verificar se o módulo btusb já reconhece o VID:PID
    if modinfo btusb 2>/dev/null | grep -qi "${MERCUSYS_VID}"; then
        log_success "O btusb já possui entrada para VID ${MERCUSYS_VID}."
        ensure_adapter_up
        exit 0
    fi
}

# ── Headers do kernel ───────────────────────────────────────────────────────
ensure_kernel_headers() {
    log_step "Verificando headers do kernel $KVER..."

    local headers_dir="/usr/src/linux-headers-${KVER}"

    # Se o build dir já aponta para headers funcionais, OK
    if [[ -f "/lib/modules/${KVER}/build/Module.symvers" ]]; then
        log_success "Headers do kernel encontrados."
        return
    fi

    # Verificar se os headers arch-specific existem como pacote
    if [[ -d "$headers_dir" && -f "$headers_dir/Module.symvers" ]]; then
        # Criar symlink build se necessário
        ln -sfn "$headers_dir" "/lib/modules/${KVER}/build"
        log_success "Headers encontrados em $headers_dir."
        return
    fi

    # Tentar instalar via apt
    log_info "Tentando instalar linux-headers-${KVER}..."
    if apt-get install -y "linux-headers-${KVER}" 2>/dev/null; then
        log_success "Headers instalados via apt."
        return
    fi

    # Fallback: baixar do snapshot.debian.org
    log_warning "Pacote não encontrado no repo. Buscando no snapshot.debian.org..."
    install_headers_from_snapshot
}

install_headers_from_snapshot() {
    local pkg_name="linux-headers-${KVER}"
    local common_name="linux-headers-${KVER_BASE}+deb13-common"
    local kbuild_name="linux-kbuild-${KVER_BASE}+deb13"

    # Obter versão do pacote
    local pkg_version
    pkg_version=$(curl -sf "http://snapshot.debian.org/mr/binary/${pkg_name}/" \
        | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['result'][0]['binary_version'])" 2>/dev/null) || true

    if [[ -z "$pkg_version" ]]; then
        log_error "Não foi possível encontrar headers para kernel $KVER no snapshot."
        log_error "Instale manualmente: linux-headers-${KVER}"
        exit 1
    fi

    log_info "Versão encontrada: $pkg_version"

    # Baixar e instalar cada pacote necessário
    for pkg in "$pkg_name" "$kbuild_name"; do
        local hash
        hash=$(curl -sf "http://snapshot.debian.org/mr/binary/${pkg}/${pkg_version}/binfiles" \
            | python3 -c "
import json, sys
for r in json.load(sys.stdin)['result']:
    if r['architecture'] == 'amd64':
        print(r['hash']); break
" 2>/dev/null) || true

        if [[ -z "$hash" ]]; then
            log_warning "Pacote $pkg não encontrado, pulando..."
            continue
        fi

        local deb_path="/tmp/${pkg}.deb"
        log_info "Baixando $pkg..."
        curl -sfo "$deb_path" "http://snapshot.debian.org/file/${hash}"
        dpkg -i "$deb_path" 2>/dev/null || dpkg --force-depends -i "$deb_path" 2>/dev/null || true
        rm -f "$deb_path"
    done

    # Instalar common headers se não existir
    if ! dpkg -l "$common_name" &>/dev/null; then
        local common_hash
        common_hash=$(curl -sf "http://snapshot.debian.org/mr/binary/${common_name}/${pkg_version}/binfiles" \
            | python3 -c "
import json, sys
for r in json.load(sys.stdin)['result']:
    if r['architecture'] == 'all':
        print(r['hash']); break
" 2>/dev/null) || true

        if [[ -n "$common_hash" ]]; then
            local deb_path="/tmp/${common_name}.deb"
            log_info "Baixando $common_name..."
            curl -sfo "$deb_path" "http://snapshot.debian.org/file/${common_hash}"
            dpkg -i "$deb_path" 2>/dev/null || dpkg --force-depends -i "$deb_path" 2>/dev/null || true
            rm -f "$deb_path"
        fi
    fi

    # Verificar e criar symlink
    local headers_dir="/usr/src/linux-headers-${KVER}"
    if [[ -d "$headers_dir" && -f "$headers_dir/Module.symvers" ]]; then
        ln -sfn "$headers_dir" "/lib/modules/${KVER}/build"
        log_success "Headers instalados do snapshot.debian.org."
    else
        log_error "Headers não encontrados após instalação."
        exit 1
    fi
}

# ── Build do módulo ─────────────────────────────────────────────────────────
ensure_build_tools() {
    log_step "Verificando ferramentas de compilação..."

    local missing=()
    for cmd in gcc make curl python3; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_info "Instalando: ${missing[*]}..."
        apt-get update -y >/dev/null 2>&1
        apt-get install -y build-essential curl python3 >/dev/null 2>&1
    fi

    log_success "Ferramentas de compilação OK."
}

download_and_patch_btusb() {
    log_step "Preparando código-fonte do btusb..."

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Baixar btusb.c
    log_info "Baixando btusb.c (kernel v${KVER_MAJOR})..."
    if ! curl -sfo btusb.c "$BTUSB_URL"; then
        log_error "Falha ao baixar btusb.c de $BTUSB_URL"
        exit 1
    fi

    # Verificar se já tem o patch
    if grep -q "0x${MERCUSYS_VID}" btusb.c; then
        log_success "btusb.c já contém entrada para Mercusys."
    else
        # Encontrar o bloco "Additional Realtek 8761BUV" e inserir após a última entrada
        log_info "Adicionando Mercusys (${MERCUSYS_VID}:${MERCUSYS_PID}) na tabela Realtek..."

        # Encontrar a linha do último device 8761BUV (antes do bloco 8821AE)
        local insert_after
        insert_after=$(grep -n "Additional Realtek 8821AE" btusb.c | head -1 | cut -d: -f1)

        if [[ -z "$insert_after" ]]; then
            log_error "Não foi possível encontrar ponto de inserção no btusb.c"
            exit 1
        fi

        # Inserir antes do comentário 8821AE (na linha em branco anterior)
        local insert_line=$((insert_after - 1))
        sed -i "${insert_line}i\\\\t/* Mercusys RTL8761BUV (MA30) */\n\t{ USB_DEVICE(0x${MERCUSYS_VID}, 0x${MERCUSYS_PID}), .driver_info = BTUSB_REALTEK |\n\t\t\t\t\t\t     BTUSB_WIDEBAND_SPEECH }," btusb.c

        log_success "Patch aplicado no btusb.c."
    fi

    # Baixar headers internos do BT
    for h in "${BT_HEADERS[@]}"; do
        curl -sfo "$h" "https://raw.githubusercontent.com/torvalds/linux/v${KVER_MAJOR}/drivers/bluetooth/${h}" || true
    done

    # hci_codec.h pode estar em net/bluetooth
    if [[ ! -s hci_codec.h ]] || [[ $(wc -c < hci_codec.h) -lt 50 ]]; then
        curl -sfo hci_codec.h "https://raw.githubusercontent.com/torvalds/linux/v${KVER_MAJOR}/net/bluetooth/hci_codec.h" 2>/dev/null || true
    fi

    # Criar Makefile
    cat > Makefile << EOF
KDIR ?= /lib/modules/\$(shell uname -r)/build
obj-m += btusb.o

all:
	make -C \$(KDIR) M=\$(PWD) modules

clean:
	make -C \$(KDIR) M=\$(PWD) clean
EOF

    log_success "Código-fonte preparado em $BUILD_DIR."
}

build_module() {
    log_step "Compilando módulo btusb patcheado..."

    cd "$BUILD_DIR"
    make clean 2>/dev/null || true

    if ! make 2>&1; then
        log_error "Falha na compilação. Verifique os headers do kernel."
        exit 1
    fi

    if [[ ! -f btusb.ko ]]; then
        log_error "btusb.ko não foi gerado."
        exit 1
    fi

    # Verificar vermagic
    local module_ver
    module_ver=$(strings btusb.ko | grep -oP 'vermagic=\K[^ ]+' | head -1)

    if [[ "$module_ver" != "$KVER" ]]; then
        log_error "Vermagic mismatch: módulo=$module_ver, kernel=$KVER"
        exit 1
    fi

    log_success "Módulo compilado: btusb.ko (vermagic=$module_ver)"
}

install_module() {
    log_step "Instalando módulo patcheado..."

    local original="/lib/modules/${KVER}/kernel/drivers/bluetooth/btusb.ko.xz"
    local backup="${original}.bak-mercusys"

    # Backup do original (apenas na primeira vez)
    if [[ -f "$original" && ! -f "$backup" ]]; then
        cp "$original" "$backup"
        log_info "Backup do original salvo em $backup"
    fi

    # O carregador do kernel exige XZ com CRC32; o padrão CRC64 falha com
    # "decompression failed with status 6" durante o modprobe.
    cd "$BUILD_DIR"
    xz --check=crc32 -fk btusb.ko
    cp btusb.ko.xz "$original"

    # Atualizar dependências
    depmod -a

    log_success "Módulo instalado em $original"
}

reload_module() {
    log_step "Recarregando módulo btusb..."

    # Parar bluetooth sem bloquear indefinidamente em dispositivos conectados.
    systemctl stop bluetooth 2>/dev/null || true
    sleep 1

    if lsmod | grep -q '^btusb '; then
        if ! timeout 10 rmmod btusb 2>/dev/null; then
            log_warning "Não foi possível descarregar btusb agora. Reinicie para aplicar o módulo."
            systemctl start bluetooth 2>/dev/null || true
            return
        fi
        sleep 1
    fi

    if ! timeout 15 modprobe btusb; then
        log_warning "Não foi possível carregar btusb agora. Reinicie para aplicar o módulo."
        systemctl start bluetooth 2>/dev/null || true
        return
    fi

    sleep 2

    # Verificar se firmware carregou
    if dmesg | tail -30 | grep -q "RTL:.*loading.*rtl8761bu"; then
        log_success "Firmware Realtek carregado com sucesso!"
    else
        log_warning "Firmware não detectado nos logs. Pode ser necessário reconectar o dongle."
    fi

    # Reiniciar bluetooth
    systemctl start bluetooth 2>/dev/null || true
    sleep 1
}


# ── Ativação ────────────────────────────────────────────────────────────────
ensure_adapter_up() {
    log_step "Ativando adaptador Mercusys..."

    # Desbloquear rfkill
    if command -v rfkill &>/dev/null; then
        rfkill unblock bluetooth 2>/dev/null || true
    fi

    # Encontrar o hci do Mercusys
    local mercusys_hci=""
    for hci_dir in /sys/class/bluetooth/hci*/; do
        local dev_path
        dev_path=$(readlink -f "$hci_dir/device" 2>/dev/null) || continue
        local product
        product=$(cat "$dev_path/../product" 2>/dev/null) || continue
        if [[ "$product" == *MERCUSYS* ]] || [[ "$product" == *Mercusys* ]] || [[ "$product" == *mercusys* ]]; then
            mercusys_hci=$(basename "$hci_dir")
            break
        fi
    done

    if [[ -z "$mercusys_hci" ]]; then
        log_warning "Interface HCI do Mercusys não encontrada."
        return
    fi

    log_info "Mercusys está em $mercusys_hci"

    # Nome exibido pelo Blueman e pelo bluetoothctl.
    local address
    address=$(hciconfig "$mercusys_hci" 2>/dev/null | awk '/BD Address:/ {print $3; exit}')
    if [[ -n "$address" ]] && printf 'select %s\nsystem-alias "%s"\n' "$address" "$BT_ALIAS" | bluetoothctl >/dev/null 2>&1; then
        log_success "Nome do adaptador definido como: $BT_ALIAS"
    else
        log_warning "Não foi possível definir o nome do adaptador Bluetooth."
    fi


    # Ligar
    hciconfig "$mercusys_hci" up 2>/dev/null || true
    sleep 1

    # Verificar
    local state
    state=$(hciconfig "$mercusys_hci" 2>/dev/null | head -3)

    if echo "$state" | grep -q "UP RUNNING"; then
        log_success "$mercusys_hci está UP e funcionando!"
    else
        log_warning "$mercusys_hci não subiu. Tente reconectar o dongle e executar novamente."
    fi

    # Teste rápido de scan
    log_info "Testando scan BT (5s)..."
    local scan_output
    scan_output=$(timeout 6 hcitool -i "$mercusys_hci" inq 2>/dev/null || true)
    local devices=0
    if [[ -n "$scan_output" ]]; then
        devices=$(grep -c ":" <<< "$scan_output" || true)
    fi

    if [[ "$devices" -gt 0 ]]; then
        log_success "Scan encontrou $devices dispositivo(s)!"
    else
        log_info "Nenhum dispositivo encontrado no scan rápido (normal se não há BT próximo)."
    fi
}

# ── Restauração ─────────────────────────────────────────────────────────────
restore_original() {
    log_step "Restaurando módulo btusb original..."

    local original="/lib/modules/${KVER}/kernel/drivers/bluetooth/btusb.ko.xz"
    local backup="${original}.bak-mercusys"
    # Compatibilidade com o backup criado pela instalação manual anterior.
    [[ -f "$backup" ]] || backup="${original}.bak"

    if [[ -f "$backup" ]]; then
        cp "$backup" "$original"
        depmod -a
        log_success "Módulo original restaurado. Reinicie para aplicar."
    else
        log_error "Backup não encontrado para $original"
        exit 1
    fi
}


# ── Main ────────────────────────────────────────────────────────────────────
main() {
    echo -e "${CYAN}${BOLD}"
    echo "==========================================================="
    echo "  Mercusys Bluetooth Adapter — btusb Patcher (RTL8761BUV)"
    echo "==========================================================="
    echo -e "${NC}"

    check_root
    check_device_present
    check_already_working
    check_btusb_needs_patch

    ensure_build_tools
    ensure_kernel_headers
    download_and_patch_btusb
    build_module
    install_module
    reload_module
    ensure_adapter_up

    # Limpeza
    rm -rf "$BUILD_DIR"

    echo -e "\n${GREEN}${BOLD}==========================================================="
    echo "  PATCH APLICADO COM SUCESSO!"
    echo "===========================================================${NC}"
    echo -e "O dongle Mercusys BT agora carrega o firmware Realtek RTL8761BUV."
    echo -e ""
    echo -e "Notas:"
    echo -e "  • O patch sobrevive reboots, mas NÃO atualizações de kernel."
    echo -e "  • Após atualizar o kernel, reexecute: ${BOLD}sudo $0${NC}"
    echo -e "  • Para restaurar o módulo original: ${BOLD}sudo $0 --restore${NC}"
}

# ── Entry point ─────────────────────────────────────────────────────────────
case "${1:-}" in
    --restore|-r)
        check_root
        restore_original
        ;;
    --help|-h)
        echo "Uso: sudo $0 [--restore|--help]"
        echo ""
        echo "Patcha o driver btusb para suportar o dongle Mercusys BT (RTL8761BUV)."
        echo "Reexecute após cada atualização de kernel."
        echo ""
        echo "  --restore  Restaura o módulo btusb original"
        echo "  --help     Mostra esta ajuda"
        ;;
    *)
        main
        ;;
esac
