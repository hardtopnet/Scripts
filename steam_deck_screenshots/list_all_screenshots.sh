#!/bin/bash

# Default directory
DIR=${1:-~/Pictures}
# Default file extension filter
EXT=${2:-*.??g}

# Show all screenshots, excluding thumbnails. Filter by the provided extension
find "$DIR" -type d -name "thumbnails" -prune -o -type f -iname "$EXT" -print -follow
