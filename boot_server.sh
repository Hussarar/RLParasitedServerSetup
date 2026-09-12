#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/1"

MIN_RAM="6G"
MAX_RAM="8G"
FORGE_JAR="forge-1.12.2-14.23.5.2860.jar"

# Change directory into the server folder
cd "$SERVER_DIR" || exit 1

java -Xms${MIN_RAM} -Xmx${MAX_RAM} -jar ${FORGE_JAR} nogui
