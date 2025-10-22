#!/bin/bash

SCREEN_LAYOUTS=($(ls -1 ~/.screenlayout/))

echo "Choose a screen layout:"
for i in "${!SCREEN_LAYOUTS[@]}"; do
  echo "$((i+1)). ${SCREEN_LAYOUTS[$i]}"
done

read -p "Enter layout (1-N): " CHOICE

SELECTED_LAYOUT="${SCREEN_LAYOUTS[$((CHOICE-1))]}"

echo "Changing screen layout to $SELECTED_LAYOUT..."

~/.screenlayout/$SELECTED_LAYOUT

