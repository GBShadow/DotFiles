# ==============================================================================
# Script de Instalação e Configuração Completa do ZSH
# ==============================================================================

Este diretório contém a configuração completa do shell **ZSH** com:
- **Oh My Zsh** (base estável e plugins auxiliares: `git`, `sudo`, `colored-man-pages`, `extract`, `history`).
- **Zinit** (gerenciador ultrarrápido para carregamento assíncrono de syntax highlighting e sugestões).
- **Plugins Zinit**:
  - `fast-syntax-highlighting` (destaque de sintaxe no comando em tempo real)
  - `zsh-autosuggestions` (auto-completar baseado no histórico)
  - `zsh-completions` (definições extras de autocompleção)
  - `zsh-history-substring-search` (busca no histórico pelas setas para cima/baixo)
- **Spaceship Prompt** (prompt Zsh veloz, minimalista e personalizável, carregado como tema do Oh My Zsh).
- **Funções auxiliares para YouTube / MPV** (`playv`, `playa`, `playpl`, `playpla`, `setres`, `playhelp`).

---

### 🚀 Instalação Rápida

Basta executar o script `setup.sh`:

```bash
chmod +x setup.sh
./setup.sh
```

O script instala as dependências necessárias (`zsh`, `zinit`, `oh-my-zsh` e `spaceship-prompt`), copia o `.zshrc` e define o ZSH como shell padrão.
