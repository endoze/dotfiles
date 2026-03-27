#!/usr/bin/env bash

case "$1" in
  memory)
    read -r _ mem_total _ <<< "$(grep MemTotal /proc/meminfo)"
    read -r _ mem_avail _ <<< "$(grep MemAvailable /proc/meminfo)"
    used=$((mem_total - mem_avail))
    echo "$((used * 100 / mem_total))"
    ;;
  cpu)
    nproc=$(nproc)
    load=$(cut -d' ' -f1 /proc/loadavg)
    # Convert load average to percentage of total cores
    # Use awk since we need floating point math
    echo "$load $nproc" | awk '{printf "%.0f", ($1 / $2) * 100}'
    ;;
  *)
    echo "0"
    ;;
esac
