#!/bin/bash
PREV_TOTAL=0
PREV_IDLE=0
OUT_FILE="/tmp/quickshell_sysmon.out"
TMP_FILE="/tmp/quickshell_sysmon.tmp"

while true; do
  # 1. RAM (%)
  RAM=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

  # 2. CPU (%)
  CPU_LINE=$(head -n 1 /proc/stat)
  IDLE=$(echo "$CPU_LINE" | awk '{print $5}')
  TOTAL=$(echo "$CPU_LINE" | awk '{for(i=2;i<=NF;i++) t+=$i; print t}')
  
  if [ "$PREV_TOTAL" -eq 0 ]; then
    CPU=0
  else
    DIFF_IDLE=$((IDLE - PREV_IDLE))
    DIFF_TOTAL=$((TOTAL - PREV_TOTAL))
    if [ "$DIFF_TOTAL" -gt 0 ]; then
        CPU=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))
    else
        CPU=0
    fi
  fi
  PREV_TOTAL=$TOTAL
  PREV_IDLE=$IDLE

  # 3. Temperature (°C)
  TEMP=0
  TEMP_FILE=$(find /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1)
  if [ -n "$TEMP_FILE" ]; then
    TEMP=$(cat "$TEMP_FILE")
  elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
  fi
  TEMP=$((TEMP / 1000))

  # ATOMIC WRITE: write to a temp file and rename it instantly
  echo "$CPU,$RAM,$TEMP" > "$TMP_FILE"
  mv "$TMP_FILE" "$OUT_FILE"
  
  sleep 2
done
