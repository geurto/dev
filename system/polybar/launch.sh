#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use 
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

echo "---" | tee -a /tmp/polybar_example.log
polybar --config=$HOME/.config/polybar/config.ini example 2>&1 | tee -a /tmp/polybar_example.log & disown

echo "Bar launched..."
