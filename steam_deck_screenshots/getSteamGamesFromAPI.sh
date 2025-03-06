#!/bin/bash
SCRIPT_DIR=~/scripts
curl 'https://api.steampowered.com/ISteamApps/GetAppList/v2/' -o "$SCRIPT_DIR/steam-api.json"
