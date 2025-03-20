#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
$STEAM_API=steam-api.json

curl 'https://api.steampowered.com/ISteamApps/GetAppList/v2/' -o "$SCRIPT_DIR/$STEAM_API"
