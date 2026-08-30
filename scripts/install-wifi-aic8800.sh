#!/usr/bin/env bash

#############################################################################
# Universal AIC8800 Wi-Fi 6 & Bluetooth Driver Installer (Offline Ready)
# Supported Distributions:
#   - Debian / Ubuntu / Linux Mint / Pop!_OS
#   - Fedora / RHEL / AlmaLinux / Rocky Linux
#   - Arch Linux / Manjaro / EndeavourOS / CachyOS
#   - openSUSE Tumbleweed / Leap
#############################################################################

set -euo pipefail

# Visual styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DRV_NAME="aic8800"
DRV_VERSION="1.0.0"
SRC_DIR="/usr/src/${DRV_NAME}-${DRV_VERSION}"
MODULE_NAME="aic8800_fdrv"
GIT_REPO="https://github.com/shenmintao/aic8800d80.git"
FALLBACK_LOCAL_SRC="/usr/src/aic8800-1.0.0"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMBEDDED_DRIVER_DIR="${SCRIPT_DIR}/driver-aic8800"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step()    { echo -e "\n${CYAN}${BOLD}==>${NC} ${BOLD}$1${NC}"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root. Please run with: sudo $0"
        exit 1
    fi
}

detect_distro() {
    log_step "Detecting Linux distribution and package manager..."
    
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
        DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
        DISTRO_NAME="Generic Linux"
    fi

    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
    else
        log_error "No supported package manager found (apt, dnf, pacman, zypper)."
        exit 1
    fi

    log_success "Detected: $DISTRO_NAME (using $PKG_MANAGER)"
}

install_dependencies() {
    log_step "Installing build dependencies and kernel headers..."
    local kver
    kver=$(uname -r)

    case "$PKG_MANAGER" in
        apt)
            log_info "Updating package repositories..."
            apt-get update -y || true

            local pkgs=(dkms build-essential git bc usb-modeswitch eject)
            if apt-cache show "linux-headers-$kver" &>/dev/null; then
                pkgs+=("linux-headers-$kver")
            else
                pkgs+=("linux-headers-generic")
            fi

            log_info "Installing: ${pkgs[*]}"
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
            ;;

        dnf)
            log_info "Installing Fedora/RHEL dependencies..."
            local pkgs=(dkms make gcc git bc usb_modeswitch util-linux kernel-devel)
            
            if dnf list available "kernel-devel-$kver" &>/dev/null; then
                pkgs+=("kernel-devel-$kver")
            fi
            if dnf list available "kernel-headers-$kver" &>/dev/null; then
                pkgs+=("kernel-headers-$kver")
            else
                pkgs+=("kernel-headers")
            fi

            log_info "Installing: ${pkgs[*]}"
            dnf install -y "${pkgs[@]}"
            ;;

        pacman)
            log_info "Updating Arch package database..."
            pacman -Sy --noconfirm

            local pkgs=(dkms base-devel git bc usb_modeswitch util-linux)
            
            if [[ "$kver" =~ cachyos ]]; then
                pkgs+=("linux-cachyos-headers")
            elif [[ "$kver" =~ lts ]]; then
                pkgs+=("linux-lts-headers")
            elif [[ "$kver" =~ zen ]]; then
                pkgs+=("linux-zen-headers")
            elif [[ "$kver" =~ hardened ]]; then
                pkgs+=("linux-hardened-headers")
            else
                pkgs+=("linux-headers")
            fi

            log_info "Installing: ${pkgs[*]}"
            pacman -S --needed --noconfirm "${pkgs[@]}" || pacman -S --needed --noconfirm dkms base-devel git bc usb_modeswitch
            ;;

        zypper)
            log_info "Installing openSUSE dependencies..."
            local pkgs=(dkms make gcc git bc usb_modeswitch kernel-devel kernel-default-devel)
            zypper --non-interactive install "${pkgs[@]}"
            ;;
    esac

    log_success "Dependencies installed successfully."
}

prepare_source() {
    log_step "Preparing driver source code..."

    # 1. Prioridade máxima: Arquivos embutidos no próprio repositório dotfiles (100% Offline)
    if [[ -d "$EMBEDDED_DRIVER_DIR" && -f "$EMBEDDED_DRIVER_DIR/install.sh" ]]; then
        log_info "Using embedded driver and firmware from dotfiles repo ($EMBEDDED_DRIVER_DIR)..."
        rm -rf "$SRC_DIR"
        mkdir -p "$SRC_DIR"
        cp -a "$EMBEDDED_DRIVER_DIR/"* "$SRC_DIR/"
    # 2. Prioridade 2: Diretório local /usr/src
    elif [[ -d "$FALLBACK_LOCAL_SRC" && -f "$FALLBACK_LOCAL_SRC/install.sh" ]]; then
        log_info "Using local source tree from $FALLBACK_LOCAL_SRC..."
        rm -rf "$SRC_DIR"
        mkdir -p "$SRC_DIR"
        cp -a "$FALLBACK_LOCAL_SRC/"* "$SRC_DIR/"
    # 3. Fallback: Clonar do GitHub
    else
        log_info "Cloning latest source from $GIT_REPO..."
        rm -rf "$SRC_DIR"
        git clone --depth 1 "$GIT_REPO" "$SRC_DIR"
    fi

    # Criar configuração DKMS
    cat > "$SRC_DIR/dkms.conf" << EOF
PACKAGE_NAME="${DRV_NAME}"
PACKAGE_VERSION="${DRV_VERSION}"
CLEAN="cd drivers/aic8800 && make clean"
MAKE="cd drivers/aic8800 && make"

BUILT_MODULE_NAME[0]="aic8800_fdrv"
BUILT_MODULE_LOCATION[0]="drivers/aic8800/aic8800_fdrv"
DEST_MODULE_LOCATION[0]="/updates/dkms"

BUILT_MODULE_NAME[1]="aic_load_fw"
BUILT_MODULE_LOCATION[1]="drivers/aic8800/aic_load_fw"
DEST_MODULE_LOCATION[1]="/updates/dkms"

BUILT_MODULE_NAME[2]="aic_zlp_quirk"
BUILT_MODULE_LOCATION[2]="drivers/aic8800/aic_zlp_quirk"
DEST_MODULE_LOCATION[2]="/updates/dkms"

AUTOINSTALL="yes"
EOF

    log_success "Driver source prepared at $SRC_DIR"
}

install_firmware_and_rules() {
    log_step "Installing firmware and udev rules..."

    mkdir -p /lib/firmware
    if [[ -d "$SRC_DIR/fw" ]]; then
        cp -r "$SRC_DIR/fw/"aic8800* /lib/firmware/ 2>/dev/null || true
    fi
    if [[ -d "$SRC_DIR/firmware" ]]; then
        cp -r "$SRC_DIR/firmware/"* /lib/firmware/ 2>/dev/null || true
    fi

    mkdir -p /usr/lib/udev/rules.d /etc/usb_modeswitch.d
    if [[ -f "$SRC_DIR/aic.rules" ]]; then
        cp "$SRC_DIR/aic.rules" /usr/lib/udev/rules.d/90-aic8800-mode-switch.rules
    fi
    if [[ -f "$SRC_DIR/usb_modeswitch/1111_1111" ]]; then
        cp "$SRC_DIR/usb_modeswitch/1111_1111" /etc/usb_modeswitch.d/1111:1111
    fi

    if command -v udevadm &>/dev/null; then
        udevadm control --reload-rules || true
        udevadm trigger || true
    fi

    log_success "Firmware and udev rules registered."
}

build_and_install_dkms() {
    log_step "Building and registering kernel module with DKMS..."

    if dkms status "$DRV_NAME/$DRV_VERSION" &>/dev/null; then
        log_info "Removing older DKMS registration..."
        dkms remove "$DRV_NAME/$DRV_VERSION" --all 2>/dev/null || true
    fi

    log_info "Adding module to DKMS..."
    dkms add -m "$DRV_NAME" -v "$DRV_VERSION"

    log_info "Compiling module for kernel $(uname -r)..."
    dkms build -m "$DRV_NAME" -v "$DRV_VERSION"

    log_info "Installing module..."
    dkms install -m "$DRV_NAME" -v "$DRV_VERSION" --force

    log_success "DKMS installation complete! Driver will auto-rebuild on future kernel upgrades."
}

load_and_test_driver() {
    log_step "Loading kernel modules and testing wireless interface..."
    depmod -a || true

    modprobe -r "$MODULE_NAME" 2>/dev/null || true

    log_info "Loading $MODULE_NAME..."
    if modprobe "$MODULE_NAME"; then
        log_success "Kernel module $MODULE_NAME loaded successfully!"
    else
        log_warning "Could not load $MODULE_NAME immediately. A reboot may be required."
    fi

    modprobe aic_zlp_quirk 2>/dev/null || true

    sleep 1
    echo ""
    log_info "Verifying loaded modules:"
    lsmod | grep -E "aic|btusb" || log_warning "No aic modules currently in lsmod."

    echo ""
    log_info "Checking wireless network interfaces:"
    if command -v ip &>/dev/null; then
        ip link show | grep -E "wlan|wlp|wl" || log_warning "No wireless interface detected yet (plug in the adapter if disconnected)."
    fi
}

main() {
    echo -e "${CYAN}${BOLD}"
    echo "==========================================================="
    echo "  Universal AIC8800 Wi-Fi 6 / BT Driver Installer"
    echo "==========================================================="
    echo -e "${NC}"

    check_root
    detect_distro
    install_dependencies
    prepare_source
    install_firmware_and_rules
    build_and_install_dkms
    load_and_test_driver

    echo -e "\n${GREEN}${BOLD}==========================================================="
    echo "  INSTALLATION COMPLETED SUCCESSFULLY!"
    echo "===========================================================${NC}"
    echo -e "Your AIC8800 Wi-Fi 6 adapter is now active and configured."
    echo -e "You can connect to Wi-Fi using your network manager or 'nmcli device wifi connect'."
}

main "$@"
