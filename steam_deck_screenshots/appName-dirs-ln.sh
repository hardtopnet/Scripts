#!/bin/bash

# Constants and URLs
USER_ID=**USER_ID**
LINK_DIR=~/Pictures  # Directory where symbolic links will be created
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")  # Directory where the script is located
API_URL="https://api.steampowered.com/ISteamApps/GetAppList/v2/"
NON_STEAM_GAMES="non-steam-games.json"
STEAM_API="steam-api.json"

# Function to sanitize names
sanitize_name() {
    local input="$1"
    local sanitized_name

    # Apply transformations
    sanitized_name=$(echo "$input" | sed 's/[^a-zA-Z0-9._-]/_/g; s/[™®]//g')
    sanitized_name=$(echo "$sanitized_name" | sed 's/ /_/g; s/__/_/g')

    # Return the result
    echo "$sanitized_name"
}

# Target directory (default: /home/deck/.local/share/Steam/userdata/$USER_ID/760/remote)
TARGET_DIR=${1:-/home/deck/.local/share/Steam/userdata/$USER_ID/760/remote}

# Echo the constants values
echo 
echo "Constants values:"
echo "USER_ID: $USER_ID"
echo "LINK_DIR: $LINK_DIR"
echo "TARGET_DIR: $TARGET_DIR"
echo "API_URL: $API_URL"
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "NON_STEAM_GAMES: $NON_STEAM_GAMES"
echo "STEAM_API: $STEAM_API"

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo 
    echo "Error: Specified directory '$TARGET_DIR' does not exist."
    echo 
    exit 1
fi

# Verify that jq is installed
if ! command -v jq &> /dev/null; then
    echo 
    echo "Error: 'jq' is required to run this script. Install it with 'sudo apt install jq' or equivalent."
    echo 
    exit 1
fi

# Retrieve the complete list of applications once
echo 
echo "Fetching data from Steam..."
response=$(curl -s "$API_URL")
if [ -z "$response" ]; then
    echo 
    echo "Error: Unable to fetch data from the Steam API."
    echo 
    exit 1
fi

# Initialize counters and lists
iterated_count=0
link_count=0
iterated_files=()
linked_files=()

# Populate linked_files with existing symlinks in the LINK_DIR
for link in "$LINK_DIR"/*; do
    if [ -L "$link" ]; then
        linked_files+=("$(basename "$link")")
    fi
done

# Process subdirectories
for dir in "$TARGET_DIR"/*; do
    # Remove the trailing slash to get the directory name
    appid=$(basename "$dir")

    if [[ "$appid" -eq 7 ]]; then
        continue
    fi

    iterated_count=$((iterated_count + 1))
    echo -e "\nProcessing directory: $appid"

    # Check if the name is a number
    if [[ "$appid" =~ ^[0-9]+$ ]]; then

        # Search in hardcoded non-steam links
        app_name=$(jq -r --argjson appid "$appid" '.applist.apps[] | select(.appid == $appid) | .name' "$SCRIPT_DIR/$NON_STEAM_GAMES" | head -n 1)

        if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
            echo "    [NON-STEAM] $app_name"
            sanitized_name=$(sanitize_name "$app_name")
        else
            # Search in snapshot API on disk
            app_name=$(jq -r --argjson appid "$appid" '.applist.apps[] | select(.appid == $appid) | .name' "$SCRIPT_DIR/$STEAM_API" | head -n 1)

            if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
                echo "    [SNAPSHOT] $app_name"
                sanitized_name=$(sanitize_name "$app_name")
            else
                # Search in API
                app_info=$(echo "$response" | jq -r ".applist.apps[] | select(.appid == $appid)")
                app_name=$(echo "$response" | jq -r "first(.applist.apps[] | select(.appid == $appid)) | .name")

                if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
                    echo "    [API] $app_name"
                    sanitized_name=$(sanitize_name "$app_name")
                else 
                    # Search on the Steam Store HTML page for the AppID
                    steam_store_url="https://store.steampowered.com/app/$appid"
                    page_content=$(curl -s -L "$steam_store_url" | tr -d '\0')

                    # Extract the game title from the <title> tag
                    app_name=$(echo "$page_content" | grep -oP '(?<=<title>).*?(?= on Steam</title>)')
                    # Clean up to keep only the game name
                    app_name=$(echo "$app_name" | sed -E 's/^Save [0-9]+%? on (.+)/\1/' | sed 's/[™®]//g')

                    if [ -n "$app_name" ]; then
                        echo "    [WEB] $app_name"
                        sanitized_name=$(sanitize_name "$app_name")
                    else
                        echo "    [ID] $appid"
                        sanitized_name=$appid
                    fi
                fi
            fi
        fi

        iterated_files+=("$sanitized_name")

        # Check if the symbolic link target already exists
        if [ ! -L "$LINK_DIR/$sanitized_name" ]; then
            # Create a new symbolic link with the app name
            ln -sfn "$dir/screenshots" "$LINK_DIR/$sanitized_name"
            echo "- Symbolic link created: $sanitized_name -> $dir"
            link_count=$((link_count + 1))
        else
            # If the symbolic link name already exists, update its target
            current_target=$(readlink "$LINK_DIR/$sanitized_name")
            if [ "$current_target" != "$dir/screenshots" ]; then
                ln -sfn "$dir/screenshots" "$LINK_DIR/$sanitized_name"
                echo "- Symbolic link updated: $sanitized_name -> $dir"
                link_count=$((link_count + 1))
            else
                echo "- Existing symbolic link unchanged: $sanitized_name -> $dir"
            fi
        fi
    else
        echo "Ignored: $dir is not a valid appid."
    fi
done

# Add hardcoded non-steam games links from $NON_STEAM_GAMES
if jq -e '.applist.hardcoded' "$SCRIPT_DIR/$NON_STEAM_GAMES" > /dev/null; then
    hardcoded_apps=$(jq -c '.applist.hardcoded[]' "$SCRIPT_DIR/$NON_STEAM_GAMES")

    # Iterate over each hardcoded app using a for loop
    for app in $(echo "$hardcoded_apps" | jq -r '. | @base64'); do
        _jq() {
            echo "${app}" | base64 --decode | jq -r "${1}"
        }

        appfolder=$(_jq '.appfolder')
        name=$(_jq '.name')

        if [ -n "$appfolder" ] && [ -n "$name" ]; then
            echo -e "\nProcessing directory: $appfolder"
            echo "    [HARDCODED] $name"
            sanitized_name=$(sanitize_name "$name")
            iterated_files+=("$sanitized_name")
            iterated_count=$((iterated_count + 1))

            # Check if the symbolic link target already exists
            if [ ! -L "$LINK_DIR/$sanitized_name" ]; then
                ln -sfn "$appfolder" "$LINK_DIR/$sanitized_name"
                echo "- Symbolic link created: $sanitized_name -> $appfolder"
                link_count=$((link_count + 1))
            else
                # If the symbolic link name already exists, update its target
                current_target=$(readlink "$LINK_DIR/$sanitized_name")
                if [ "$current_target" != "$appfolder" ]; then
                    ln -sfn "$appfolder" "$LINK_DIR/$sanitized_name"
                    echo "- Symbolic link updated: $sanitized_name -> $appfolder"
                    link_count=$((link_count + 1))
                else
                    echo "- Existing symbolic link unchanged: $sanitized_name -> $appfolder"
                fi
            fi
        else
            echo "Error: 'appfolder' or 'name' missing for a hardcoded element."
        fi
    done
else
    echo -e "\n    [INFO] No hardcoded links found in $NON_STEAM_GAMES"
fi

# Display summary debug line
total_links=$(find "$LINK_DIR" -maxdepth 1 -type l | wc -l)
echo -e "\n\nProcessing completed.\nIterated through $iterated_count elements.\nTotal symbolic links in the output directory: $total_links"

# Compare iterated files and linked files
echo -e "\nFiles iterated but not linked:"
iterated_output=false
for file in "${iterated_files[@]}"; do
    if [[ ! " ${linked_files[@]} " =~ " $file " ]]; then
        echo "  - $file"
        iterated_output=true
    fi
done
if [ "$iterated_output" = false ]; then
    echo "  - none"
fi

echo -e "\nFiles linked but not iterated:"
linked_output=false
for file in "${linked_files[@]}"; do
    if [[ ! " ${iterated_files[@]} " =~ " $file " ]]; then
        echo "  - $file"
        linked_output=true
    fi
done
if [ "$linked_output" = false ]; then
    echo "  - none"
fi

echo 