#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LOGFILE="$SCRIPT_DIR/server_setup.log"
RM_MODS_FILE="$BASE_DIR/removal_modlist.txt"

log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "Error: Python 3 is not installed or not in PATH. Exiting..."
    exit 1
fi

# Java 8 Check & Download
if ! dpkg -s openjdk-8-jre-headless &> /dev/null; then
    sudo apt -qq update &> /dev/null && sudo apt install -y -qq openjdk-8-jre-headless &> /dev/null && log "Installed Java 8"
else
    log "Java 8 is already installed."
fi

echo "What is the Name of the Server?"
read -p "> " servername

echo "What type of Server do you want to setup?"
echo "[1] RLCraftParasited"
echo "[2] RLCraft Dregora Parasited"
echo "[3] ShyCraft Parasited"
read -p "> " servertype

echo "What configration would you like to add?"
echo "Input the numbers in sequence if you want to combine Unparasited and HCC"
echo "[1] Add UnParasited Config"
echo "[2] Add Hardcore Config (HCC)"
echo "[3] Add Omega Hardcore Config (OmegaHCC)"
read -p "> " config

echo "Do you want to install "
echo "Input the numbers in sequence if you want to add both Mods"
echo "[1] Morpheus? (50% Sleep Mod)"
echo "[2] Chunk Pregeneration?"
read -p "> " addon

if [[ -e "./$servername" ]]; then
    echo -e "Error: Server folder '$servername' already exists! Exiting..."
    exit 1
fi

mkdir -pv ./$servername

# Gamefile Downloads
cd ./$servername

if [[ "$servertype" == 1 ]]; then
    curl -sLO https://github.com/Nischhelm/RLCraftParasited/releases/download/Aug14-2026/RLCraft.Parasited.zip
    unzip RLCraft.Parasited.zip -d ./PARA
    rm RLCraft.Parasited.zip
fi
if [[ "$servertype" == 2 ]]; then
    curl -sLO https://github.com/Nischhelm/RLCraftParasited/releases/download/Aug14-2026/Dregora.Parasited.zip
    unzip Dregora.Parasited.zip -d ./PARA
    rm Dregora.Parasited.zip
fi
if [[ "$servertype" == 3 ]]; then
    curl -sLO https://github.com/Nischhelm/RLCraftParasited/releases/download/Aug14-2026/ShyCraft.Parasited.zip
    unzip ShyCraft.Parasited.zip -d ./PARA
    rm ShyCraft.Parasited.zip
fi

# Download Forge Server Installer
curl -sLO https://maven.minecraftforge.net/net/minecraftforge/forge/1.12.2-14.23.5.2860/forge-1.12.2-14.23.5.2860-installer.jar && log "Installed Forge Server Installer"

# Run the Forge Server Installer
java -jar forge-1.12.2-14.23.5.2860-installer.jar --installServer &> /dev/null && log "Forge Installer Installed"

echo "eula=true" > eula.txt

echo "stop" | java -Xms6G -Xmx8G -jar forge-1.12.2-14.23.5.2860.jar nogui &> /dev/null && log "Server Files generated"

cp -rfv ./PARA/manifest.json ./
cp -rfv ./PARA/overrides/* ./ &> /dev/null && rm -rf ./PARA &> /dev/null && log "Para Copied"

# UnParasited Download
if [[ "$config" == *1* ]]; then
    log "Installed UnParasited Files"
    unzip -o 'Parasited Unparasited.zip'
    rm 'Parasited Unparasited.zip'
fi

# HCC Download
if [[ "$config" == *2* ]]; then
    log "Installed HCC Files"
    unzip -o 'Parasited HCC.zip'
    rm 'Parasited HCC.zip'
fi

# OmegaHCC Download
if [[ "$config" == *3* ]]; then
    log "Installed OmegaHCC Files"
    unzip -o 'Parasited OmegaHCC_Server.zip'
    rm 'Parasited OmegaHCC_Server.zip'
fi

log "Downloading Mods from manifest.json..."

python3 "$BASE_DIR/manifestreader.py"

#Mod removals
if [[ -f "$RM_MODS_FILE" ]]; then
    log "Removing Client Mods"
    while IFS= read -r mod || [[ -n "$mod" ]]; do
        [[ -z "$mod" || "$mod" =~ ^# ]] && continue
        rm -f mods/${mod}* 2>/dev/null
    done < "$RM_MODS_FILE"
else
    log "$RM_MODS_FILE not found."
fi

# Remove the Forge Server Installer
rm -v forge-1.12.2-14.23.5.2860-installer.jar

echo "Creating boot_server.sh in RLServSetupper..."

cat << 'EOF' > ../boot_server.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/__SERVERNAME__"

MIN_RAM="6G"
MAX_RAM="8G"
FORGE_JAR="forge-1.12.2-14.23.5.2860.jar"

# Change directory into the server folder
cd "$SERVER_DIR" || exit 1

java -Xms${MIN_RAM} -Xmx${MAX_RAM} -jar ${FORGE_JAR} nogui
EOF

# Inject the actual server folder name
sed -i "s/__SERVERNAME__/$servername/g" ../boot_server.sh

# Make boot_server.sh executable
chmod +x ../boot_server.sh
echo -e "Created boot_server.sh in RLServSetupper!"

cd ./mods

if [[ "$addon" == *1* ]]; then
    log "Downloading Morpheus"
    curl -fL -A "Mozilla/5.0" -o "Morpheus-1.12.2-3.5.106.jar" "https://edge.forgecdn.net/files/2664/449/Morpheus-1.12.2-3.5.106.jar" && log "Installed Morpheus"
fi

if [[ "$addon" == *2* ]]; then
    log "Downloading Chunk Pregenerator"
    curl -fL -A "Mozilla/5.0" -o "Chunk-Pregenerator-V1.12-2.5.1.jar" "https://edge.forgecdn.net/files/3490/718/Chunk%20Pregenerator-V1.12-2.5.1.jar" && log "Installed Chunk Pregenerator"
fi

#https://www.curseforge.com/minecraft/mc-mods/chunkpregenerator/files/3490718

log "Finished installation! Start the Server by executing the boot_server.sh"
echo "Don't forget to Portforward (25565 TCP/UDP) for other people to join!"
echo "And also 24454 UDP for the Simple Voice Chat Mod"

#TODO: Add Morpheus, Add PreGen
