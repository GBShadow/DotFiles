# 🌙 KDE Plasma — Retroiluminação do teclado USB

Configuração para fazer a iluminação do teclado USB funcionar no **KDE Plasma
(Wayland)**, onde o `xset` usado pela configuração original do i3 não tem efeito.

## 🧩 O problema

Muitos teclados USB genéricos não expõem um controle próprio de iluminação.
A luz é ligada/desligada pelo **LED de Scroll Lock**, a única saída HID que o
teclado oferece:

```
/sys/class/leds/input37::scrolllock/brightness
```

Dois obstáculos no Linux:

1. **`xset` só funciona no X11.** No Wayland (KWin/Plasma/Niri) o comando
   `xset led named "Scroll Lock"` não altera o hardware.
2. **O arquivo `brightness` é `root:root 0644`**, então o usuário comum não
   consegue escrever nele via `sysfs` (necessário no Wayland).

## ✅ A solução

| Arquivo | Destino | Função |
| :--- | :--- | :--- |
| `../scripts/kbd-backlight.sh` | `~/.local/bin/kbd-backlight.sh` | Script portátil (sysfs + fallback `xset`) |
| `../scripts/udev/90-kbd-backlight.rules` | `/etc/udev/rules.d/` | Libera escrita no LED para o grupo `wheel` |
| `autostart/kbd-backlight.desktop` | `~/.config/autostart/` | Liga a luz no login |
| `kglobalaccel/kbd-backlight.desktop` | `~/.local/share/kglobalaccel/` | Comando global do Plasma (atalho) |

O script detecta automaticamente o LED do teclado USB (ignorando o teclado
PS/2 interno do notebook) e funciona em X11 e Wayland.

## 🚀 Instalação

```bash
./setup.sh
```

O instalador:

1. copia o script para `~/.local/bin`;
2. instala a regra udev em `/etc/udev/rules.d` e recarrega (`sudo`);
3. instala o autostart (luz ligada no login);
4. registra o atalho global **`Meta+K`** para alternar a luz;
5. liga a luz imediatamente.

> Para trocar o atalho antes de instalar:
> `KBD_BACKLIGHT_SHORTCUT="Meta+ScrollLock" ./setup.sh`

### Permissões da regra udev

A regra libera o LED para o grupo **`wheel`** (comum em Arch/Fedora). Se o seu
usuário não estiver nesse grupo, edite `../scripts/udev/90-kbd-backlight.rules`
trocando `wheel` por `video` ou `input`, e reinstale.

Verifique os grupos do usuário com `groups`.

## ⌨️ Uso

```bash
kbd-backlight.sh on       # liga
kbd-backlight.sh off      # desliga
kbd-backlight.sh toggle   # alterna
kbd-backlight.sh status   # mostra o estado
```

- **Atalho global:** `Meta+K` (após novo login).
- **Tecla `Scroll Lock`:** também alterna a luz nativamente.

Para forçar um LED específico:

```bash
KBD_BACKLIGHT_LED=/sys/class/leds/input37::scrolllock kbd-backlight.sh on
```

## 📝 Observações

- O atalho global passa a valer **após sair e entrar novamente** na sessão: no
  Plasma 6 o `kwin_wayland` hospeda o `KGlobalAccelD` e lê os comandos globais
  na inicialização (não há recarga em tempo real pela linha de comando).
- Se o atalho não aparecer, confira em
  **Configurações do Sistema → Atalhos → Comandos** um item
  “Retroiluminação do Teclado”.
- A configuração original do **i3** (`i3/config`) continua válida: o mesmo
  script agora também tenta o `sysfs` antes do `xset`.
