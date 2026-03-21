#!/usr/bin/env bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zjstatus"
mkdir -p "$CACHE_DIR"

LOCK_FILE="$CACHE_DIR/weather.lock"
ICON_CACHE="$CACHE_DIR/weather_icon"
LOC_CACHE="$CACHE_DIR/location"
LOC_MAX_AGE=600    # refresh location every 10 minutes
WEATHER_MAX_AGE=300  # refresh weather every 5 minutes

now=$(date +%s)

file_age() {
  local file="$1"
  if [ -f "$file" ]; then
    echo $(( now - $(stat -f %m "$file" 2>/dev/null || echo 0) ))
  else
    echo 999999
  fi
}

# If weather cache is fresh, just return cached data
if [ "$(file_age "$ICON_CACHE")" -lt "$WEATHER_MAX_AGE" ]; then
  cat "$ICON_CACHE" 2>/dev/null
  exit 0
fi

# If another instance is already running, use cached data
# Also clean up stale lock files older than 30 seconds
if [ -f "$LOCK_FILE" ]; then
  if [ "$(file_age "$LOCK_FILE")" -lt 30 ]; then
    cat "$ICON_CACHE" 2>/dev/null
    exit 0
  fi
  rm -f "$LOCK_FILE"
fi

trap 'rm -f "$LOCK_FILE"' EXIT
echo $$ > "$LOCK_FILE"

# Use cached location if fresh enough
if [ -f "$LOC_CACHE" ] && [ "$(file_age "$LOC_CACHE")" -lt "$LOC_MAX_AGE" ]; then
  lat=$(cut -d',' -f1 "$LOC_CACHE")
  long=$(cut -d',' -f2 "$LOC_CACHE")
fi

# Fetch location if not cached
if [ -z "$lat" ] || [ -z "$long" ]; then
  loc=$(curl -s --max-time 5 ipinfo.io | jq -r '.loc // empty')

  if [ -z "$loc" ]; then
    cat "$ICON_CACHE" 2>/dev/null
    exit 0
  fi

  lat=$(echo "$loc" | cut -d',' -f1)
  long=$(echo "$loc" | cut -d',' -f2)
  echo "${lat},${long}" > "$LOC_CACHE"
fi
temperature_unit="fahrenheit"

case "$temperature_unit" in
"fahrenheit") temp_unit="F" ;;
"celsius") temp_unit="C" ;;
esac

weather=$(curl -s --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${long}&current=temperature,weathercode&temperature_unit=$temperature_unit")

tem=$(echo "$weather" | jq -r '.current.temperature // empty')
wea=$(echo "$weather" | jq -r '.current.weathercode // empty')

if [ -z "$tem" ] || [ -z "$wea" ]; then
  cat "$ICON_CACHE" 2>/dev/null
  exit 0
fi

tem="${tem}°${temp_unit}"

ICON_CLEAR=$'\UE30D'
ICON_CLOUDY=$'\UE312'
ICON_FOG=$'\UE313'
ICON_DRIZZLE=$'\UE319'
ICON_RAIN=$'\UE318'
ICON_SNOW=$'\U000F0F36'
ICON_SHOWERS=$'\UE318'
ICON_THUNDER=$'\UE31D'
ICON_DEFAULT=$'\U000F0599'

case "$wea" in
0 | 1) curwea=$ICON_CLEAR ;;
2 | 3) curwea=$ICON_CLOUDY ;;
45 | 48) curwea=$ICON_FOG ;;
51 | 53 | 55 | 56 | 57) curwea=$ICON_DRIZZLE ;;
61 | 63 | 65 | 66 | 67) curwea=$ICON_RAIN ;;
71 | 73 | 75 | 77 | 85 | 86) curwea=$ICON_SNOW ;;
80 | 81 | 82) curwea=$ICON_SHOWERS ;;
95 | 96 | 99) curwea=$ICON_THUNDER ;;
*) curwea=$ICON_DEFAULT ;;
esac

echo "$tem" > "$CACHE_DIR/weather_data"
echo "$curwea" > "$ICON_CACHE"
echo "$curwea"
