#!/usr/bin/env bash
# ==============================================================================
# Script de Configuração do Ambiente de Desenvolvimento C# / .NET para Neovim
# ==============================================================================
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}     Configuração do Ambiente C# / .NET (SDK + Mason LSP + Tools)            ${NC}"
echo -e "${BLUE}==============================================================================${NC}"

# 1. Verificar e Instalar .NET SDK
echo -e "\n${BLUE}==> [1/4] Verificando .NET SDK...${NC}"
if dotnet --list-sdks 2>/dev/null | grep -q "8\.0\|9\.0"; then
    echo -e "${GREEN}✔ .NET SDK já está instalado:${NC}"
    dotnet --list-sdks
else
    echo -e "${YELLOW}⚡ .NET SDK não encontrado. Instalando dotnet-sdk-8.0 via APT...${NC}"
    if command -v sudo >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y dotnet-sdk-8.0
    else
        echo -e "${RED}❌ sudo não encontrado. Execute como root: apt update && apt install -y dotnet-sdk-8.0${NC}"
        exit 1
    fi
    echo -e "${GREEN}✔ .NET SDK 8.0 instalado com sucesso!${NC}"
fi

# 2. Configurar Variáveis de Ambiente no Shell (.bashrc / .zshrc)
echo -e "\n${BLUE}==> [2/4] Configurando variáveis de ambiente do .NET...${NC}"

DOTNET_ENV_SNIPPET='
# .NET Environment Variables
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export PATH="$PATH:$HOME/.dotnet/tools"
'

for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$RC" ]; then
        if ! grep -q "HOME/.dotnet/tools" "$RC"; then
            echo -e "--> Adicionando ~/.dotnet/tools ao PATH em $RC..."
            echo "$DOTNET_ENV_SNIPPET" >> "$RC"
        else
            echo -e "--> $RC já possui ~/.dotnet/tools configurado."
        fi
    fi
done

# Exportar para a sessão atual do script
export PATH="$PATH:$HOME/.dotnet/tools"

# 3. Instalar Ferramentas Globais do .NET (CSharpier, dotnet-ef)
echo -e "\n${BLUE}==> [3/4] Instalando ferramentas globais do .NET...${NC}"
if command -v dotnet >/dev/null 2>&1; then
    # CSharpier (Formatador utilizado pelo LazyVim / Conform)
    if ! dotnet tool list -g | grep -q "csharpier"; then
        echo "--> Instalando csharpier (formatador C#)..."
        dotnet tool install -g csharpier || true
    else
        echo -e "${GREEN}✔ csharpier já instalado.${NC}"
    fi

    # dotnet-ef (Entity Framework Core CLI)
    if ! dotnet tool list -g | grep -q "dotnet-ef"; then
        echo "--> Instalando dotnet-ef..."
        dotnet tool install -g dotnet-ef || true
    else
        echo -e "${GREEN}✔ dotnet-ef já instalado.${NC}"
    fi
fi

# 4. Instalar e Validar Servidores LSP no Neovim via Mason
echo -e "\n${BLUE}==> [4/4] Verificando pacotes do Mason no Neovim (OmniSharp, CSharpier, NetCoreDbg)...${NC}"
if command -v nvim >/dev/null 2>&1; then
    echo "--> Sincronizando pacotes do Mason para C# no Neovim..."
    nvim --headless "+MasonInstall omnisharp csharpier netcoredbg" "+qa" 2>/dev/null || true
    echo -e "${GREEN}✔ Pacotes Mason verificados!${NC}"
else
    echo -e "${YELLOW}⚠️ Neovim não encontrado no PATH.${NC}"
fi

# Verificação Final
echo -e "\n${BLUE}==============================================================================${NC}"
echo -e "${GREEN}✔ Ambiente C# / .NET configurado com sucesso!${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo -e "Resumo do ambiente:"
echo -e "  - Dotnet SDKs: $(dotnet --list-sdks 2>/dev/null || echo 'nenhum')"
echo -e "  - Dotnet Runtimes: $(dotnet --list-runtimes 2>/dev/null | wc -l) instalados"
echo -e "  - Ferramentas Globais: $(dotnet tool list -g 2>/dev/null | tail -n +3 | awk '{print $1}' | paste -sd, - || echo 'nenhuma')"
echo -e "\nPara recarregar o shell execute: ${YELLOW}source ~/.zshrc${NC} (ou ${YELLOW}source ~/.bashrc${NC})"
