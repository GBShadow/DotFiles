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

Três obstáculos no Linux:

1. **`xset` só funciona no X11.** No Wayland (KWin/Plasma/Niri) o comando
   `xset led named "Scroll Lock"` não altera o hardware.
2. **O arquivo `brightness` é `root:root 0644`**, então o usuário comum não
   consegue escrever nele via `sysfs` (necessário no Wayland).
3. **O KWin reescreve os LEDs do teclado.** A cada mudança de Caps Lock/Num
   Lock, o `kwin_wayland` grava *todos* os LEDs (`write()` em
   `/dev/input/eventN`, evento `EV_LED`) e envia **sempre** o bit de Scroll Lock
   como `0`. Resultado: a luz apaga ao apertar Caps/Num Lock e não volta.

   Diagnóstico confirmado por `ftrace` (kprobe em `input_inject_event`):

   ```
   kwin_wayland-2967 [010] iie: type=0x11 code=0x2 value=0x0
    => input_inject_event
    => evdev_write
    => vfs_write
   ```

   (`0x11` = `EV_LED`, `code 0x2` = `LED_SCROLLL`, `value 0` = desligado.)

   O mesmo acontece pelo console/VT: o LED nasce preso ao trigger
   `kbd-scrolllock`, que o console reescreve conforme o estado de Scroll Lock do
   VT (e de novo a cada teclado conectado).

## ✅ A solução

| Arquivo | Destino | Função |
| :--- | :--- | :--- |
| `../scripts/kbd-backlight.sh` | `~/.local/bin/kbd-backlight.sh` | Script portátil (sysfs + fallback `xset`) e modo `keep` |
| `../scripts/udev/90-kbd-backlight.rules` | `/etc/udev/rules.d/` | Libera escrita em `brightness` e `trigger` para o grupo `wheel` |
| `systemd/kbd-backlight.service` | `~/.config/systemd/user/` | Serviço *keep*: mantém a luz ligada, desfazendo a sobrescrita do KWin |

O script detecta automaticamente o LED do teclado USB (ignorando o teclado
PS/2 interno do notebook), solta o LED do trigger do console e funciona em X11
e Wayland. O serviço de usuário (modo `keep`) reafirma o estado desejado
algumas vezes por segundo — custo desprezível — então Caps/Num Lock não apagam
mais a luz.

## 🚀 Instalação

```bash
./setup.sh
```

O instalador:

1. copia o script para `~/.local/bin`;
2. instala a regra udev em `/etc/udev/rules.d` e recarrega (`sudo`);
3. instala e habilita o serviço de usuário `kbd-backlight.service`;
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
kbd-backlight.sh keep     # modo serviço (mantém o estado desejado)
```

- **Atalho global:** `Meta+K` (após novo login).

Para forçar um LED específico:

```bash
KBD_BACKLIGHT_LED=/sys/class/leds/input37::scrolllock kbd-backlight.sh on
```

### Serviço

```bash
systemctl --user status  kbd-backlight.service
systemctl --user restart kbd-backlight.service
systemctl --user disable --now kbd-backlight.service   # desativar
```

O estado desejado fica em `$XDG_RUNTIME_DIR/kbd-backlight.state` (padrão:
ligado). Ele é usado pelo modo `keep`, então `on`/`off`/`toggle` continuam
valendo mesmo com o serviço rodando.

## 📝 Observações

- A tecla física **Scroll Lock** não alterna mais a luz de forma confiável: o
  KWin e o serviço `keep` reescrevem o LED. Use o atalho `Meta+K`.
- O atalho global passa a valer **após sair e entrar novamente** na sessão: no
  Plasma 6 o `kwin_wayland` hospeda o `KGlobalAccelD` e lê os comandos globais
  na inicialização (não há recarga em tempo real pela linha de comando).
- Se o atalho não aparecer, confira em
  **Configurações do Sistema → Atalhos → Comandos** um item
  “Retroiluminação do Teclado”.
- A configuração original do **i3** (`i3/config`) continua válida: o mesmo
  script agora também tenta o `sysfs` antes do `xset`.
- Se o teclado for reconectado, o LED muda de nome (`inputNN::scrolllock`); o
  modo `keep` re-detecta automaticamente.
