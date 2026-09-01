# ==============================================================================
# MPV Media Player - Configuração de Alta Performance
# ==============================================================================

Configuração customizada e otimizada para o reprodutor multimídia **mpv**, com foco em máxima fluidez, baixo consumo de CPU e conveniência.

### ✨ Recursos & Otimizações
- **Auto-Resume**: Lembra a posição exata de onde você parou de assistir ao fechar o vídeo (`save-position-on-quit=yes`).
- **Aceleração Gráfica por Hardware**: Decodificação via Intel VA-API (`hwdec=vaapi`) com perfil leve (`profile=fast`) para execução a frio sem travamentos.
- **Filtro de Streaming Otimizado**: Prioriza streams em H.264 (`avc1`) até 720p ao abrir links do YouTube/web com `yt-dlp`.
- **Buffer & Cache Otimizado**: Buffer local estendido para evitar engasgos em conexões instáveis.

---

### 🚀 Instalação Rápida

Basta executar o script `setup.sh`:

```bash
chmod +x setup.sh
./setup.sh
```
