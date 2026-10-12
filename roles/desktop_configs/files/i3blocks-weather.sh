#!/usr/bin/env bash

weather=$(curl -s -m 5 'wttr.in/?format=%c+%t' 2>/dev/null)
[ -z "$weather" ] && exit 0

echo "$weather"
