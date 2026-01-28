#!/bin/bash
MON=$HOME/.monkeytype/docker/
if [[ -d  $MON ]]; then
cd $MON
docker compose up -d
fi
