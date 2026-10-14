#!/usr/bin/env bash

focused_window=$(i3-msg -t get_tree | jq -r '.. | objects | select(.focused == true and .window_properties != null) | [.window_properties.class // "", (.window // "null" | tostring)] | join("|")')
IFS='|' read -r window_class window_id <<< "$focused_window"

if [[ "${window_class,,}" == "alacritty" ]]; then
  window_pid=$(xprop -id "$window_id" _NET_WM_PID | awk -F'= ' '/_NET_WM_PID\(CARDINAL\)/ {print $2}')
  if [[ "$window_pid" =~ ^[0-9]+$ ]]; then
    for shell in zsh bash fish; do
      shell_pid=$(pgrep -P "$window_pid" -x "$shell")
      [[ -n "$shell_pid" ]] && break
    done
    if [[ -n "$shell_pid" ]]; then
      working_directory=$(readlink "/proc/$shell_pid/cwd")
      if [[ -n "$working_directory" ]]; then
        exec emacsclient -c -a emacs --eval "(magit-status \"$working_directory\")"
      fi
    fi
  fi
fi

exec emacsclient -c -a emacs --eval '(magit-status)'
