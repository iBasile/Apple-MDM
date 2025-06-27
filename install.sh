#!/bin/bash

set -e

### --------------------------
### 🎛️ Fonctions d'affichage
### --------------------------

function afficher_etape() {
    local etape="$1"
    local total="$2"
    local titre="$3"
    clear
    echo -e "\e[44mInstallation de NanoMDM — Étape ${etape}/${total} : ${titre} \e[0m"
    echo
}

function pause() {
    read -rp "\n👉 Appuyez sur Entrée pour continuer..."
}

### --------------------------
### 🔐 Vérifier sudo
### --------------------------

if [[ $EUID -ne 0 ]]; then
    echo "⚠️ Ce script doit être exécuté avec sudo."
    echo "👉 Relancez avec : sudo $0"
    exit 1
fi

### --------------------------
### 📁 Dossier d'installation
### --------------------------
INSTALL_DIR="/opt/nanomdm"
BINDIR="/usr/local/bin"

### --------------------------
### 🚧 Préparation
### --------------------------
afficher_etape 1 6 "Préparation de l'environnement"
echo "📁 Création du dossier $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

### --------------------------
### ⬇️ Téléchargement SCEP Server
### --------------------------
afficher_etape 2 6 "Téléchargement de SCEP Server"
SCEP_VERSION="v2.1.0"
SCEP_URL="https://github.com/micromdm/scep/releases/download/${SCEP_VERSION}/scepserver-darwin-amd64-${SCEP_VERSION}.zip"
curl -LO "$SCEP_URL"
unzip -o "scepserver-darwin-amd64-${SCEP_VERSION}.zip"
mv scepserver-darwin-amd64 scepserver
chmod +x scepserver

### Initialisation de la CA
if [ ! -f "depot/index.txt" ]; then
    echo "🔐 Initialisation de la CA SCEP..."
    ./scepserver ca init
fi

### --------------------------
### ⬇️ Téléchargement NanoMDM
### --------------------------
afficher_etape 3 6 "Téléchargement de NanoMDM"
NMDM_VERSION="v0.2.0"
NMDM_URL="https://github.com/micromdm/nanomdm/releases/download/${NMDM_VERSION}/nanomdm-darwin-amd64-${NMDM_VERSION}.zip"
curl -LO "$NMDM_URL"
unzip -o "nanomdm-darwin-amd64-${NMDM_VERSION}.zip"
mv nanomdm-darwin-amd64 nanomdm
chmod +x nanomdm

### --------------------------
### ⚙️ Configuration
### --------------------------
afficher_etape 4 6 "Configuration de base"
read -rp "🌐 Nom de domaine ou adresse IP (pour le MDM) : " SERVER_HOSTNAME
read -rp "📍 Port HTTP pour NanoMDM (par défaut : 443) : " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-443}

cat > config.env <<EOF
NANOMDM_API_KEY="changeme-key"
NANOMDM_PUSH_CERT=""
NANOMDM_PUSH_KEY=""
NANOMDM_LISTEN_ADDR=":${SERVER_PORT}"
NANOMDM_SERVER_URL="https://${SERVER_HOSTNAME}"
EOF

### --------------------------
### 🚀 Création service systemd (lancement auto)
### --------------------------
afficher_etape 5 6 "Création du service systemd"
SERVICE_FILE="/Library/LaunchDaemons/com.nanomdm.plist"

cat > "$SERVICE_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nanomdm</string>
    <key>ProgramArguments</key>
    <array>
        <string>${INSTALL_DIR}/nanomdm</string>
        <string>-config</string>
        <string>${INSTALL_DIR}/config.env</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${INSTALL_DIR}/nanomdm.log</string>
    <key>StandardErrorPath</key>
    <string>${INSTALL_DIR}/nanomdm.err</string>
</dict>
</plist>
EOF

chmod 644 "$SERVICE_FILE"
chown root:wheel "$SERVICE_FILE"
launchctl load "$SERVICE_FILE"

### --------------------------
### ✅ Terminé
### --------------------------
afficher_etape 6 6 "Installation terminée"
echo "✅ NanoMDM est installé et configuré dans $INSTALL_DIR."
echo "📦 SCEP Server disponible avec : $INSTALL_DIR/scepserver"
echo "🚀 NanoMDM démarrera automatiquement au démarrage du système."
pause
