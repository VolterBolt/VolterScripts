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

# VolterScripts identity for PaperMC Downloads Service
USER_AGENT="VolterScripts/1.0 (https://github.com/VolterBolt/VolterScripts)"

# Plugin versions selected for this setup
ESSENTIALS_VERSION="2.20.1"
VAULT_VERSION="1.7.3"

VIA_VERSION="5.12.0"
VIA_BACKWARDS_VERSION="5.12.0"

echo
echo "=================================================="
echo "          VOLTER SERVER INSTALLER"
echo "=================================================="
echo
echo "Minecraft : Paper ${MC_VERSION}"
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

if ! command -v jq >/dev/null 2>&1; then
    echo
    echo "ERROR: jq is not installed."
    echo "Install it with:"
    echo
    echo "pkg install jq"
    exit 1
fi

echo "Java detected:"
java -version 2>&1 | head -n 1

echo
echo "wget detected."
echo "jq detected."

# ============================================================
# CREATE SERVER
# ============================================================

echo
echo "[2/7] Creating server directory..."

mkdir -p "$SERVER_DIR"
mkdir -p "$PLUGINS_DIR"

cd "$SERVER_DIR"

# ============================================================
# PAPER
# ============================================================

echo
echo "[3/7] Installing Paper ${MC_VERSION}..."

echo "Checking PaperMC Downloads Service..."

BUILDS_URL="https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}/builds"

BUILDS_RESPONSE=$(wget -qO- \
    --header="User-Agent: ${USER_AGENT}" \
    "$BUILDS_URL") || {
        echo
        echo "ERROR: Could not contact PaperMC Downloads Service."
        echo "URL:"
        echo "$BUILDS_URL"
        exit 1
    }

# Check whether PaperMC returned an API error object.
if echo "$BUILDS_RESPONSE" | jq -e '.ok == false' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$BUILDS_RESPONSE" | jq -r '.message // "Unknown PaperMC API error"')

    echo
    echo "ERROR: PaperMC Downloads Service returned an error."
    echo "Message: $ERROR_MSG"
    exit 1
fi

# Get latest stable Paper build.
PAPER_BUILD=$(echo "$BUILDS_RESPONSE" | jq -r '
    first(.[] | select(.channel == "STABLE") | .id) // "null"
')

# Get the official Paper JAR filename.
PAPER_JAR=$(echo "$BUILDS_RESPONSE" | jq -r '
    first(.[] | select(.channel == "STABLE") | .downloads."server:default".name) // "null"
')

# Get the official Paper download URL.
DOWNLOAD_URL=$(echo "$BUILDS_RESPONSE" | jq -r '
    first(.[] | select(.channel == "STABLE") | .downloads."server:default".url) // "null"
')

if [ "$PAPER_BUILD" = "null" ] || [ -z "$PAPER_BUILD" ]; then
    echo
    echo "ERROR: No stable Paper build found for Minecraft ${MC_VERSION}."
    exit 1
fi

if [ "$PAPER_JAR" = "null" ] || [ -z "$PAPER_JAR" ]; then
    echo
    echo "ERROR: Paper JAR filename was not provided by the API."
    exit 1
fi

if [ "$DOWNLOAD_URL" = "null" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo
    echo "ERROR: Paper download URL was not provided by the API."
    exit 1
fi

echo
echo "Paper build found : ${PAPER_BUILD}"
echo "Paper JAR         : ${PAPER_JAR}"

if [ -f "$PAPER_JAR" ]; then
    echo "Paper already exists."
else
    echo
    echo "Downloading Paper ${PAPER_BUILD}..."

    wget --show-progress \
        --header="User-Agent: ${USER_AGENT}" \
        -O "$PAPER_JAR" \
        "$DOWNLOAD_URL"

    echo
    echo "Paper download complete."
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

echo "EULA accepted."

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
# OPTIONAL LEGACY SUPPORT
# ============================================================

echo
echo "ViaRewind:"
echo
echo "ViaRewind is optional and is intended for"
echo "very old Minecraft clients such as 1.8.x / 1.7.x."
echo
echo "It is NOT automatically installed because"
echo "this installer does not want to depend on an"
echo "unverified hardcoded release URL."
echo

# ============================================================
# GEYSER
# ============================================================

echo
echo "=================================================="
echo "GEYSER NOTICE"
echo "=================================================="
echo
echo "Minecraft Java server : Paper ${MC_VERSION}"
echo
echo "Geyser-Spigot is not being installed automatically"
echo "for this 1.20.4 setup."
echo
echo "For Bedrock crossplay, use a compatible"
echo "Geyser standalone / proxy-based setup instead."
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
# INSTALLATION SUMMARY
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
echo "Minecraft:"
echo "  Paper ${MC_VERSION}"
echo
echo "Paper build:"
echo "  ${PAPER_BUILD}"
echo
echo "Paper JAR:"
echo "  ${PAPER_JAR}"
echo
echo "Installed plugins:"
echo

find "$PLUGINS_DIR" -maxdepth 1 -type f -name "*.jar" \
    -printf "  %f\n" 2>/dev/null || ls -1 "$PLUGINS_DIR"/*.jar

echo
echo "EULA:"
echo "  Accepted"
echo
echo "Start server:"
echo
echo "  cd \"$SERVER_DIR\""
echo "  ./start.sh"
echo
echo "=================================================="
echo
