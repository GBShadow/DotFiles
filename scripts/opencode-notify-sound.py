#!/usr/bin/env python3
"""
Instala o som de notificação do OpenCode e aponta a config attention.sounds
para ele.

Equivalente no opencode da extensão notify-sound.ts do omp: o som toca
quando o agente encerra a volta. No opencode esse evento é o som "done" —
"subagent_done" para subagentes —, configurados em
~/.config/opencode/cli.json.

O som é o mesmo dos dois agentes (Ragnarok Level Up!), por isso fica em
home/sounds/ e é instalado nos dois lugares.

Uso: opencode-notify-sound.py <caminho-do-som>
"""

import json
import os
import shutil
import sys
import time

CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".config", "opencode")
CONFIG_FILE = os.path.join(CONFIG_DIR, "cli.json")
SOUND_DIR = os.path.join(CONFIG_DIR, "sounds")

# Os eventos que tocam o som de conclusão da volta.
SOUND_EVENTS = ("done", "subagent_done")


def install_sound(source: str) -> str:
    """Copia o som para o diretório de sons do opencode e devolve o caminho."""
    os.makedirs(SOUND_DIR, exist_ok=True)
    destination = os.path.join(SOUND_DIR, os.path.basename(source))
    shutil.copyfile(source, destination)
    return destination


def patch_config(sound_path: str) -> bool:
    """
    Aponta attention.sounds para o som instalado.

    O cli.json é do usuário: o que já existe é preservado, e só o bloco
    attention é mexido. Devolve False quando o arquivo não é JSON válido —
    nesse caso é melhor não tocar do que destruir a config.
    """
    config = {}
    current = ""
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, encoding="utf-8") as handle:
            current = handle.read()
        if current.strip():
            try:
                config = json.loads(current)
            except json.JSONDecodeError as error:
                print(f"ERRO: {CONFIG_FILE} não é JSON válido ({error}). Não foi tocado.")
                return False

    attention = config.get("attention")
    if not isinstance(attention, dict):
        attention = {}
    sounds = attention.get("sounds")
    if not isinstance(sounds, dict):
        sounds = {}
    for event in SOUND_EVENTS:
        sounds[event] = sound_path
    attention["sounds"] = sounds
    attention["sound"] = True
    config["attention"] = attention

    content = json.dumps(config, indent=2, ensure_ascii=False) + "\n"
    if content == current:
        print(f"{CONFIG_FILE} já está no estado desejado.")
        return True

    backup = f"{CONFIG_FILE}.bak.{int(time.time())}"
    if os.path.exists(CONFIG_FILE):
        shutil.copyfile(CONFIG_FILE, backup)
        print(f"Backup: {backup}")

    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w", encoding="utf-8") as handle:
        handle.write(content)
    return True


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Uso: {os.path.basename(sys.argv[0])} <caminho-do-som>", file=sys.stderr)
        return 2

    source = sys.argv[1]
    if not os.path.isfile(source):
        print(f"ERRO: som não encontrado: {source}", file=sys.stderr)
        return 1

    sound_path = install_sound(source)
    if not patch_config(sound_path):
        return 1

    print(f"Som instalado em {sound_path}")
    print(f"attention.sounds: {', '.join(SOUND_EVENTS)} -> {sound_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
