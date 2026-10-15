#!/usr/bin/env bash
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
mode_file="$config_home/theme-mode"
mode="${1:-toggle}"
if [[ "$mode" == toggle ]]; then
  if [[ -f "$mode_file" && "$(<"$mode_file")" == light ]]; then
    mode=dark
  else
    mode=light
  fi
fi
case "$mode" in
  dark|light) ;;
  *) printf 'usage: %s [dark|light|toggle]\n' "$0" >&2; exit 2 ;;
esac

mkdir -p "$config_home/alacritty/themes" "$config_home/i3"
printf '%s\n' "$mode" > "$mode_file"

if [[ "$mode" == light ]]; then
  ln -sfn "$config_home/alacritty/themes/nord-light.toml" "$config_home/alacritty/themes/current.toml"
  theme=doom-nord-light
else
  ln -sfn "$config_home/alacritty/themes/nord.toml" "$config_home/alacritty/themes/current.toml"
  theme=doom-nord
fi

ln -sfn "$config_home/i3/theme-bar-$mode.conf" "$config_home/i3/theme-bar.conf"

if command -v alacritty >/dev/null 2>&1 && pgrep -x alacritty >/dev/null 2>&1; then
  touch "$config_home/alacritty/alacritty.toml"
fi

if command -v emacsclient >/dev/null 2>&1 && emacsclient -e '(featurep '\''doom-themes)' >/dev/null 2>&1; then
  emacsclient -e "(progn (mapc #'disable-theme custom-enabled-themes) (load-theme '$theme t))" >/dev/null
fi

if command -v i3-msg >/dev/null 2>&1 && i3-msg -t get_version >/dev/null 2>&1; then
  i3-msg reload >/dev/null
fi
