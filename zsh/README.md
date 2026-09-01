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
- **Starship Prompt** (prompt veloz, moderno e minimalista).
- **Funções auxiliares para YouTube / MPV** (`playv`, `playa`, `playpl`, `playpla`, `setres`, `playhelp`).

---

### 🚀 Instalação Rápida

Basta executar o script `setup.sh`:

```bash
chmod +x setup.sh
./setup.sh
```

O script cuidará de instalar as dependências necessárias (`zsh`, `starship`, `zinit`, `oh-my-zsh`), copiar o `.zshrc` e definir o ZSH como shell padrão.
