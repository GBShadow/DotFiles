# Instalação Arch Linux — GBShadow

Guia para o notebook **Celeron 1037U** (2 núcleos, Intel HD Graphics Ivy Bridge) com **SSD de 120GB**, Arch Linux puro + **i3**.

Fluxo completo:

1. Gravar a ISO no pendrive
2. Conectar internet na live ISO (adaptador AIC8800 **não funciona** na ISO — veja seção 2)
3. Particionar o SSD e instalar o Arch (seções 3 e 4)
4. Copiar os dotfiles do pendrive e rodar `arch/install.sh` (seção 5)
5. Rodar `arch/apps.sh` (aplicativos) e `arch/dev.sh` (Docker, Node, C#) — seção 5

---

## 1. Pendrive bootável

Do Linux (troque `sdX` pelo pendrive — confira com `lsblk`):

```bash
sudo dd if=archlinux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

No Windows: Rufus (modo DD) ou Ventoy.

---

## 2. Internet na live ISO — ATENÇÃO (AIC8800)

O adaptador Wi-Fi Mercusys (chip **AIC8800**) **não tem driver no kernel da ISO** — ele só funciona depois de rodar o script DKMS dos dotfiles (seção 5, `--wifi`). Para instalar, use **USB tethering do celular**:

1. Android: ative **"Compartilhar internet por USB"** com o cabo conectado.
2. Na ISO:

```bash
ip link                     # aparece como algo tipo "usb0" ou "enx..."
sudo ip link set usb0 up
sudo dhcpcd usb0            # pega IP via celular
ping -c2 archlinux.org      # testa
```

Se o notebook tiver Ethernet ou outro Wi-Fi suportado: `iwctl` → `station wlan0 scan` / `station wlan0 connect "SSID"`.

---

## 3. Particionamento do SSD 120GB

Confirme que está em modo UEFI (deve listar arquivos):

```bash
ls /sys/firmware/efi/efivars
```

Identifique o disco (`lsblk` — 120GB, ex.: `/dev/sda`). Layout:

| Partição | Tamanho    | Tipo (sgdisk)      | Sistema de arquivos | Montagem |
|----------|------------|--------------------|---------------------|----------|
| `sda1`   | 1 GiB      | EFI System (ef00)  | FAT32               | `/boot`  |
| `sda2`   | ~119 GB (resto) | Linux filesystem (8300) | **ext4** | `/`      |

Uma só partição de dados (root = home juntos), como pedido.

```bash
sudo sgdisk --zap-all /dev/sda
sudo sgdisk -n1:0:+1GiB -t1:ef00 -n2:0:0 -t2:8300 /dev/sda
lsblk                    # confere
```

### Qual formato usar e por quê: **ext4**

| FS | Veredito neste notebook | Motivo |
|----|------------------------|--------|
| **ext4** | **ESCOLHIDO** | Journaling maduro, **menor custo de CPU** (crítico em 2 núcleos fracos), TRIM nativo, recuperação excelente de queda de energia, sem surpresas. É o parâmetro para SSD SATA. |
| btrfs | Evitar | Copy-on-Write e compressão gastam CPU em cada escrita; snapshots não são o caso de uso; em SSD pequeno traz risco (espaço) sem ganho prático. |
| f2fs | Evitar | Projetado para flash **sem** controladora FTL (eMMC/SD de celular). Em SSD com FTL própria não supera ext4 e tem ferramentas de resgate menos maduras. |
| xfs | Descartável | Ótimo FS, mas sem vantagem aqui e sem shrink. ext4 é mais padrão para root. |

Ajustes de performance do ext4 neste hardware:

- **`noatime`** na partição root (fstab): elimina escrita de metadados a cada leitura de arquivo.
- **Swap: NENHUMA em disco.** Swap fica na **ZRAM** (`zram-generator`, zstd, metade da RAM) — é exatamente o truque que faz o MiniOS rodar fluido aqui: ler do disco é o gargalo, compactar na RAM não é.
- **TRIM semanal** via `fstrim.timer` — **não** use a opção de montagem `discard` (contínuo): amplifica escritas em SSD barato de 120GB sem DRAM.

> **BIOS legado (raro neste notebook):** se `ls /sys/firmware/efi/efivars` falhar, use tabela MBR com uma única partição ext4 e instale o GRUB (`grub-install --target=i386-pc`). O resto do guia assume UEFI.

---

## 4. Instalação base

```bash
# Montar o sistema
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# Instalar o sistema (inclui intel-ucode, DKMS e headers p/ o driver Wi-Fi)
pacstrap -K /mnt \
  base linux linux-firmware linux-headers base-devel git dkms \
  sudo nano neovim networkmanager intel-ucode zram-generator earlyoom \
  e2fsprogs dosfstools ntfs-3g exfatprogs man-db man-pages xdg-user-dirs

# fstab
genfstab -U /mnt >> /mnt/etc/fstab
nano /mnt/etc/fstab      # na linha do "/" troque "defaults" por "defaults,noatime"

arch-chroot /mnt
```

Dentro do chroot:

```bash
# Relógio, idioma e teclado
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/; s/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2"  > /etc/vconsole.conf

# Rede, hostname, usuários
systemctl enable NetworkManager fstrim.timer earlyoom
echo "arch" > /etc/hostname
passwd                                              # senha do root
useradd -m -G wheel gbshadow
passwd gbshadow
EDITOR=nano visudo                                  # descomentar: %wheel ALL=(ALL:ALL) ALL

# ZRAM (mesma config que o arch/install.sh usa)
tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
tee /etc/sysctl.d/99-zram.conf >/dev/null <<'EOF'
vm.swappiness = 100
vm.page-cluster = 0
EOF

# Bootloader (systemd-boot, ESP montado em /boot)
bootctl install
cat > /boot/loader/loader.conf <<'EOF'
default arch
timeout 3
EOF
PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2)
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=$PARTUUID rw rootfstype=ext4
EOF

exit    # sai do chroot
```

**Antes de reiniciar, copie os dotfiles do pendrive** (veja seção 5.1) — o sistema novo ainda não tem rede até instalar o driver Wi-Fi.

```bash
umount -R /mnt
reboot
```

---

## 5. Dotfiles e aplicativos

### 5.1 Montar o pendrive com os dotfiles

**Na live ISO (antes do primeiro reboot):**

```bash
lsblk                                   # identifica o pendrive, ex.: sdb1
mkdir -p /mnt/usb
mount /dev/sdb1 /mnt/usb
cp -a /mnt/usb/dotfiles /mnt/root/      # vai parar em /root/dotfiles no sistema novo
umount /mnt/usb
```

**Ou depois do primeiro boot (dentro do i3, terminal Alacritty):**

```bash
lsblk
# modo gráfico, sem root:
udisksctl mount -b /dev/sdb1
# ou manual: sudo mount /dev/sdb1 /mnt/usb
cp -a /run/media/$USER/*/dotfiles ~/    # ajuste o caminho conforme o lsblk
```

Se os dotfiles vieram de `/root/dotfiles` (copiados na live):

```bash
sudo mv /root/dotfiles /home/gbshadow/
sudo chown -R gbshadow:gbshadow ~/dotfiles
```

### 5.2 Rodar os instaladores

```bash
cd ~/dotfiles/arch
./install.sh          # base do sistema + otimizações + ZSH/MPV/Neovim/GitUI/i3
                      #   + configs locais do $HOME (git, tema, wallpaper) + omp
                      # responda "s" para o driver AIC8800 (ou use ./install.sh --wifi)
./apps.sh             # aplicativos (Thorium, ZapZap, Obsidian, Steam, Thunar, etc.)
./dev.sh              # desenvolvimento: Docker, nvm + Node LTS, C#/.NET (Neovim)
```

O **ZSH** é configurado pelo `install.sh` exatamente como você usa: Oh My Zsh + Zinit + Starship + `.zshrc` dos dotfiles (inclui helpers de YouTube/MPV, nvm e o alias `hd-space`), com `chsh` para o zsh.

Depois do driver Wi-Fi: `sudo reboot`, conecte no NetworkManager (ícone da bandeja) e pronto.

> Compositor **Niri** (Wayland) fica de fora de propósito — o alvo é i3/X11. Se quiser depois: `cd ~/dotfiles && ./install.sh --niri`.

---

## 6. Notas pós-instalação

- **Thunar**: gerenciador de arquivos padrão da instalação (com `thunar-volman` + `gvfs` para montar pendrives/HDs NTFS e exFAT com duplo-clique, `tumbler` para miniaturas e `thunar-archive-plugin` para "Extrair aqui" via File Roller).
- **Monitor externo**: o `.xinitrc` (aplicado pelo módulo `home/`) roda, ANTES do i3, o mesmo bloco xrandr do MiniOS: se houver monitor externo conectado, desliga o `LVDS-1` e usa o externo como primary (evita o workspace 10 fantasma). Troca em runtime: `~/.config/i3/monitors.sh`.
- **Relógio (CMOS sem bateria)**: o `arch/install.sh` cria o serviço `fix-relogio.service`, que a CADA boot força o fuso `America/Sao_Paulo`, ativa NTP com servidores brasileiros (`a.ntp.br`) e re-sincroniza o relógio depois da rede subir. Confira com `timedatectl`.
- **Configurações locais**: `.gitconfig` (auth via `gh`), `.profile`, `.bashrc`, `.gtkrc-2.0`, tema Catppuccin Mocha (`~/.themes/`) e papel de parede (`~/Pictures/1375178.png` + `.fehbg`) — todos versionados em `dotfiles/home/` e aplicados pelo `arch/install.sh`. Em qualquer máquina: `./install.sh --home`.
- **omp (Oh My Pi)**: binário instalado pelo `arch/install.sh` (instalador oficial `omp.sh/install`); configs locais (marketplaces + manifests de plugins) aplicadas pelo módulo `home/`. `natives`, skills e cache de plugins são baixados pelo próprio omp no primeiro boot.
- **Jogos (PS1/NDS)**: PS1 → DuckStation (Flatpak, já instalado); NDS → MelonDS (instalado pelo `apps.sh`). No 1037U rode `game-mode.sh on` antes de jogar (desliga o blur do picom e fixa o governor da CPU em `performance`) e `game-mode.sh off` depois. Configurações leves: DuckStation com renderer **OpenGL**, resolução interna **1x–2x**, PGXP desligado se travar; MelonDS com renderer **software** e **1x** (sem upscale).
- **Docker** (`dev.sh`): serviço ativado no boot; seu usuário entra no grupo `docker` — faça logout/login para `docker` funcionar sem `sudo`.
- **Node.js** (`dev.sh`): nvm em `~/.nvm` + versão LTS como padrão; o `.zshrc` dos dotfiles já carrega o nvm sozinho.
- **C#/.NET** (`dev.sh`): `dotnet-sdk-8.0` do pacman + `csharpier`/`dotnet-ef` globais + OmniSharp/netcoredbg no Neovim via Mason (script `scripts/setup-csharp.sh` dos dotfiles).
- **Bitwarden**: depende do chaveiro do sistema (`gnome-keyring`, instalado pelo `apps.sh`). Se pedir senha de chaveiro no primeiro uso, cadastre uma.
- **VA-API (vídeo por hardware, Ivy Bridge)**: já configurado pelo módulo MPV (`libva-intel-driver`). Teste: `vainfo | grep -i vaapi`.
- **OpenTabletDriver**: serviço já ativado pelo `apps.sh`; configure a mesa em `otd` (GUI).
- **Steam**: repositório `[multilib]` é habilitado automaticamente pelo `apps.sh`.
- **Zathura (PDF)**: navegação estilo vim (`J/K`, `f` para links) — combina com o i3.
- **Verificação rápida de saúde do SSD**: `systemctl status fstrim.timer` e `zramctl` (deve listar `/dev/zram0`).
