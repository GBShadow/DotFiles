#!/usr/bin/env bash
# ==============================================================================
# Monitor de CPU para Polybar (Catppuccin Mocha)
# - Largura fixa (evita redimensionamento ao atingir 100% ou baixar)
# - Esquema de cores por faixa de uso:
#   * Até 65%: Verde (#a6e3a1)
#   * 66% a 85%: Amarelo (#f9e2af)
#   * Acima de 85%: Vermelho (#f38ba8)
# - Texto: Base (#1e1e2e)
# ==============================================================================

STATE_FILE="${XDG_RUNTIME_DIR:-/dev/shm}/polybar_cpu_state"

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_all=$((idle + iowait))
total=$((user + nice + system + idle_all + irq + softirq + steal))

if [ ! -f "$STATE_FILE" ]; then
    prev_total=$total
    prev_idle_all=$idle_all
    sleep 0.1
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    idle_all=$((idle + iowait))
    total=$((user + nice + system + idle_all + irq + softirq + steal))
else
    read -r prev_total prev_idle_all < "$STATE_FILE" 2>/dev/null || { prev_total=0; prev_idle_all=0; }
fi

echo "$total $idle_all" > "$STATE_FILE"

diff_total=$((total - prev_total))
diff_idle=$((idle_all - prev_idle_all))

if [ "$diff_total" -gt 0 ]; then
    diff_active=$((diff_total - diff_idle))
    cpu_usage=$(( (diff_active * 100 + diff_total / 2) / diff_total ))
else
    cpu_usage=0
fi

[ "$cpu_usage" -lt 0 ] && cpu_usage=0
[ "$cpu_usage" -gt 100 ] && cpu_usage=100

# Faixas de cores:
# <= 65%: Verde (#a6e3a1)
# 66% - 85%: Amarelo (#f9e2af)
# > 85%: Vermelho (#f38ba8)
if [ "$cpu_usage" -le 65 ]; then
    bg="#a6e3a1"
elif [ "$cpu_usage" -le 85 ]; then
    bg="#f9e2af"
else
    bg="#f38ba8"
fi

fg="#1e1e2e"

# Largura estável e compacta com %3d%% (evita saltos entre 2 e 3 dígitos)
printf "%%{B%s}%%{F%s}  %3d%% %%{B-}%%{F-}\n" "$bg" "$fg" "$cpu_usage"
