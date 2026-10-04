#!/data/data/com.termux/files/usr/bin/bash

set -e

# ============================================================
# VOLTER SERVER INSTALLER
# Paper 1.20.4
# Termux / Linux
# ============================================================

SERVER_DIR="$HOME/VolterServer"
PLUGINS_DIR="$SERVER_DIR/plugins"

MC_VERSION="1.20.4"
PAPER_BUILD="499"
PAPER_JAR="paper-${MC_VERSION}-${PAPER_BUILD}.jar"

# Versions selected for this 1.20.4 setup
ESSENTIALS_VERSION="2.20.1"
VAULT_VERSION="1.7.3"

# Stable ViaVersion family known to support Paper 1.20.4
VIA_VERSION="5.12.0"
VIA_BACKWARDS_VERSION="5.12.0"

echo
echo "=================================================="
echo "          VOLTER SERVER INSTALLER"
echo "=================================================="
echo
echo "Minecraft : Paper ${MC_VERSION}"
echo "Paper     : Build ${PAPER_BUILD}"
echo "Location  : ${SERVER_DIR}"
echo

# ============================================================
# REQUIREMENTS
# ============================================================

echo "[1/7] Checking requirements..."

if ! command -v java >/dev/null 2>&1; then
    echo
    echo "ERROR: Java is not installed."
    echo "Install Java first."
    exit 1
fi

if ! command -v wget >/dev/null 2>&1; then
    echo
    echo "ERROR: wget is not installed."
    echo "Install it with:"
    echo
    echo "pkg install wget"
    exit 1
fi

echo "Java detected:"
java -version 2>&1 | head -n 1

echo

# ============================================================
# CREATE SERVER
# ============================================================

echo "[2/7] Creating server directory..."

mkdir -p "$SERVER_DIR"
mkdir -p "$PLUGINS_DIR"

cd "$SERVER_DIR"

# ============================================================
# PAPER
# ============================================================

echo "[3/7] Installing Paper ${MC_VERSION}..."

echo "Finding latest stable Paper build..."

PAPER_JSON=$(wget -qO- \
    --header="User-Agent: VolterScripts/1.0 (https://github.com/VolterBolt/VolterScripts)" \
    "https://fill.papermc.io/v3/projects/paper/${MC_VERSION}/builds")

PAPER_BUILD=$(echo "$PAPER_JSON" | jq -r '
    map(select(.channel == "STABLE")) |
    .[0].id
')

PAPER_JAR=$(echo "$PAPER_JSON" | jq -r '
    map(select(.channel == "STABLE")) |
    .[0].downloads."server:default".name
')

DOWNLOAD_URL=$(echo "$PAPER_JSON" | jq -r '
    map(select(.channel == "STABLE")) |
    .[0].downloads."server:default".url
')

if [ -z "$PAPER_BUILD" ] || [ "$PAPER_BUILD" = "null" ]; then
    echo "ERROR: Could not find a stable Paper build for ${MC_VERSION}."
    exit 1
fi

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    echo "ERROR: Could not find Paper download URL."
    exit 1
fi

echo "Paper build found: ${PAPER_BUILD}"
echo "Paper JAR: ${PAPER_JAR}"

if [ -f "$PAPER_JAR" ]; then
    echo "Paper already exists."
else
    echo "Downloading Paper ${PAPER_BUILD}..."

    wget --show-progress \
        --header="User-Agent: VolterScripts/1.0 (https://github.com/VolterBolt/VolterScripts)" \
        -O "$PAPER_JAR" \
        "$DOWNLOAD_URL"
fi

# ============================================================
# EULA
# ============================================================

echo
echo "Accepting Minecraft EULA..."

cat > "$SERVER_DIR/eula.txt" <<EOF
# Minecraft EULA
# https://aka.ms/MinecraftEULA

eula=true
EOF

# ============================================================
# DOWNLOAD FUNCTION
# ============================================================

download_plugin() {

    NAME="$1"
    URL="$2"
    FILE="$3"

    echo
    echo "-> ${NAME}"

    if [ -f "$PLUGINS_DIR/$FILE" ]; then
        echo "   Already installed."
        return
    fi

    wget --show-progress \
        -O "$PLUGINS_DIR/$FILE" \
        "$URL"

    echo "   Installed."
}

# ============================================================
# ESSENTIALSX
# ============================================================

echo
echo "[4/7] Installing EssentialsX..."

download_plugin \
    "EssentialsX ${ESSENTIALS_VERSION}" \
    "https://repo.essentialsx.net/releases/net/essentialsx/EssentialsX/${ESSENTIALS_VERSION}/EssentialsX-${ESSENTIALS_VERSION}.jar" \
    "EssentialsX.jar"

download_plugin \
    "EssentialsX Spawn ${ESSENTIALS_VERSION}" \
    "https://repo.essentialsx.net/releases/net/essentialsx/EssentialsXSpawn/${ESSENTIALS_VERSION}/EssentialsXSpawn-${ESSENTIALS_VERSION}.jar" \
    "EssentialsXSpawn.jar"

# ============================================================
# VAULT
# ============================================================

echo
echo "[5/7] Installing Vault..."

download_plugin \
    "Vault ${VAULT_VERSION}" \
    "https://github.com/MilkBowl/Vault/releases/download/${VAULT_VERSION}/Vault.jar" \
    "Vault.jar"

# ============================================================
# VIAVERSION
# ============================================================

echo
echo "[6/7] Installing version compatibility plugins..."

download_plugin \
    "ViaVersion ${VIA_VERSION}" \
    "https://github.com/ViaVersion/ViaVersion/releases/download/${VIA_VERSION}/ViaVersion-${VIA_VERSION}.jar" \
    "ViaVersion.jar"

download_plugin \
    "ViaBackwards ${VIA_BACKWARDS_VERSION}" \
    "https://github.com/ViaVersion/ViaBackwards/releases/download/${VIA_BACKWARDS_VERSION}/ViaBackwards-${VIA_BACKWARDS_VERSION}.jar" \
    "ViaBackwards.jar"

# ============================================================
# OPTIONAL VIA REWIND
# ============================================================

echo
echo "ViaRewind:"
echo
echo "ViaRewind is an optional addon for very old"
echo "1.8.x / 1.7.x clients."
echo
echo "It is intentionally not auto-downloaded here."
echo "Install it separately if legacy-client support"
echo "is actually required."
echo

# ============================================================
# GEYSER WARNING
# ============================================================

echo
echo "=================================================="
echo "GEYSER NOTICE"
echo "=================================================="
echo
echo "This server is Paper ${MC_VERSION}."
echo
echo "Current Geyser-Spigot does NOT support direct"
echo "installation on Java servers below 1.20.5."
echo
echo "For Bedrock crossplay on 1.20.4 use:"
echo
echo "  Geyser-ViaProxy / Geyser Standalone"
echo
echo "rather than pretending Geyser-Spigot is installed."
echo
echo "=================================================="

# ============================================================
# START SCRIPT
# ============================================================

echo
echo "[7/7] Creating start script..."

cat > "$SERVER_DIR/start.sh" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

cd "\$(dirname "\$0")"

exec java -Xms1G -Xmx2G -jar "$PAPER_JAR" --nogui
EOF

chmod +x "$SERVER_DIR/start.sh"

# ============================================================
# SUMMARY
# ============================================================

echo
echo
echo "=================================================="
echo "             INSTALLATION COMPLETE"
echo "=================================================="
echo
echo "Server:"
echo "  $SERVER_DIR"
echo
echo "Paper:"
echo "  $PAPER_JAR"
echo
echo "Installed plugins:"
echo

find "$PLUGINS_DIR" -maxdepth 1 -type f -name "*.jar" \
    -printf "  %f\n" 2>/dev/null || ls -1 "$PLUGINS_DIR"/*.jar

echo
echo "Start server:"
echo
echo "  cd \"$SERVER_DIR\""
echo "  ./start.sh"
echo
echo "=================================================="
echo
