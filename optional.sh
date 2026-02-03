#!/usr/bin/env bash

scripts=(
    "spotify:$HOME/sayarchi/package/spotify.sh"
    "ollama:$HOME/sayarchi/package/ollama.sh"
    "docker:$HOME/sayarchi/package/docker.sh"
    "devbox:$HOME/sayarchi/package/devbox.sh"
    "monkey:$HOME/sayarchi/setups/monkeytype.sh"
    "libinput:$HOME/sayarchi/package/libinput.sh"
    "mp3tag:$HOME/sayarchi/package/mp3tag.sh"
)

echo "Running Scripts"
for entry in "${scripts[@]}"; do
    name="${entry%%:*}"
    script="${entry##*:}"
    echo "Installing and setting up $name"
    if [[ -f "$script" ]]; then
        bash "$script"
    else
        echo "❌ Script not found: $script"
        exit 0
    fi
done
