#!/bin/bash
# rebuild_tar.sh
# Rebuilds a split 7z archive into a single .7z file

# Directory containing split 7z files
ARCHIVE_DIR="./"
# Base name of the split archive (before .001)
BASE_NAME="photopea_split"
# Output rebuilt archive
OUTPUT_FILE="photopea_rebuilt.7z"

# Ensure the output file doesn't exist
rm -f "$OUTPUT_FILE"

# Concatenate all split parts in order
cat "$ARCHIVE_DIR/$BASE_NAME".7z.* > "$OUTPUT_FILE"

echo "Rebuilt archive created: $OUTPUT_FILE"
7z x photopea_rebuilt.7z
docker load -i ./photopea_latest.tar
docker-compose up -d
