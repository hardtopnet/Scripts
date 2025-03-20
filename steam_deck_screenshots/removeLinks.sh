#!/bin/bash

# Target directory (default: current directory)
TARGET_DIR=${1:-.}

# Check if the directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: The specified directory '$TARGET_DIR' does not exist."
  exit 1
fi

# Iterate over all files and remove symbolic links
echo "Removing symbolic links in the directory: $TARGET_DIR"
for item in "$TARGET_DIR"/*; do
  if [ -L "$item" ]; then
    echo "Removing symbolic link: $item"
    rm "$item"
  fi
done

echo "All symbolic links have been removed."
