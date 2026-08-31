#!/usr/bin/env bash

#############################################################################
# Instalador Rápido do Driver AIC8800 Pré-Compilado para Batocera (x86_64)
# Não necessita de compilação ou internet: instala os binários prontos em 2 segundos!
#############################################################################

set -euo pipefail

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREBUILT_DIR="${SCRIPT_DIR}/aic8800-prebuilt"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERRO] Execute este script com sudo: sudo $0${NC}"
    exit 1
fi

echo -e "${BLUE}[INFO] Procurando partição SHARE do Batocera montada...${NC}"

BATOCERA_SHARE=""
for mountpoint in /mnt/batocera_share /media/*/SHARE /run/media/*/SHARE /userdata; do
    if [[ -d "$mountpoint/system" ]]; then
        BATOCERA_SHARE="$mountpoint"
        break
    fi
done

if [[ -z "$BATOCERA_SHARE" ]]; then
    echo -e "${YELLOW}[!] Partição SHARE não encontrada automaticamente em pontos comuns.${NC}"
    read -rp "Digite o caminho onde a partição SHARE do Batocera está montada (ex: /mnt/batocera_share): " BATOCERA_SHARE
fi

if [[ ! -d "$BATOCERA_SHARE/system" ]]; then
    echo -e "${RED}[ERRO] O caminho '$BATOCERA_SHARE' não parece ser a partição SHARE do Batocera (pasta 'system' ausente).${NC}"
    exit 1
fi

echo -e "${BLUE}[INFO] Instalando driver pré-compilado em: $BATOCERA_SHARE/system/drivers/aic8800/${NC}"
mkdir -p "$BATOCERA_SHARE/system/drivers/aic8800"
cp -r "$PREBUILT_DIR/"* "$BATOCERA_SHARE/system/drivers/aic8800/"

echo -e "${BLUE}[INFO] Configurando inicialização automática em: $BATOCERA_SHARE/system/custom.sh${NC}"
cat << 'CUSTOM_EOF' > "$BATOCERA_SHARE/system/custom.sh"
#!/bin/bash
# ===================================================================
# Script de Inicialização Automática - Driver AIC8800 no Batocera
# ===================================================================

DRV_DIR="/userdata/system/drivers/aic8800"

# 1. Monta overlay para injetar firmwares no /lib/firmware
mkdir -p /tmp/fw_upper /tmp/fw_work
mount -t overlay overlay -o lowerdir=/lib/firmware,upperdir=/tmp/fw_upper,workdir=/tmp/fw_work /lib/firmware 2>/dev/null || true

# 2. Copia os firmwares do AIC8800
if [ -d "$DRV_DIR/firmware" ]; then
    cp -r "$DRV_DIR/firmware/"* /lib/firmware/ 2>/dev/null || true
fi

# 3. Carrega os módulos de kernel pré-compilados
if [ -f "$DRV_DIR/aic_load_fw.ko" ]; then
    insmod "$DRV_DIR/aic_load_fw.ko" 2>/dev/null || true
fi

if [ -f "$DRV_DIR/aic8800_fdrv.ko" ]; then
    insmod "$DRV_DIR/aic8800_fdrv.ko" 2>/dev/null || true
fi

if [ -f "$DRV_DIR/aic_btusb.ko" ]; then
    insmod "$DRV_DIR/aic_btusb.ko" 2>/dev/null || true
fi

# 4. Ativação global de FSR para Proton / Steam / Wine
export WINE_FULLSCREEN_FSR=1
export WINE_FULLSCREEN_FSR_STRENGTH=2
export WINE_FULLSCREEN_FSR_MODE=ultra
export PROTON_FSR=1
export PROTON_FSR_STRENGTH=2
CUSTOM_EOF

chmod +x "$BATOCERA_SHARE/system/custom.sh"

echo -e "${GREEN}[SUCESSO] Driver e inicialização configurados com sucesso no Batocera!${NC}"
echo -e "Ao iniciar o Batocera, o Wi-Fi AIC8800 será ativado automaticamente."
