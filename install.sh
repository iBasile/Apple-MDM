#!/bin/bash

# Vérifie si le script est exécuté en tant que root
if [[ "$EUID" -ne 0 ]]; then
  echo "⛔️ Ce script doit être exécuté avec sudo."
  echo "➡️  Relance avec : sudo $0"
  exit 1
fi

INSTALL_DIR="/Users/$(logname)/nanomdm-setup"
SCEP_VERSION="v2.1.0"
NANOMDM_VERSION="v0.2.0"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

echo "🛠️  Bienvenue dans l'installateur NanoMDM pour macOS"
echo "📁 Dossier d'installation : $INSTALL_DIR"

# === SCEP Server ===
if [[ ! -f "scepserver-darwin-amd64" ]]; then
    echo "⬇️  Téléchargement de SCEP Server..."
    curl -LO "https://github.com/micromdm/scep/releases/download/$SCEP_VERSION/scepserver-darwin-amd64-$SCEP_VERSION.zip"
    unzip "scepserver-darwin-amd64-$SCEP_VERSION.zip"
else
    echo "✅ SCEP Server déjà présent, téléchargement ignoré."
fi

# Initialisation du CA
if [[ ! -f "ca.pem" || ! -f "ca.key" ]]; then
    echo "🔐 Initialisation d’une nouvelle autorité de certification (CA)..."
    ./scepserver-darwin-amd64 -init -key ca.key -cert ca.pem -cn "NanoMDM CA"
else
    echo "✅ Autorité de certification déjà initialisée."
fi

# === NanoMDM ===
if [[ ! -f "nanomdm-darwin-amd64" ]]; then
    echo "⬇️  Téléchargement de NanoMDM..."
    curl -LO "https://github.com/micromdm/nanomdm/releases/download/$NANOMDM_VERSION/nanomdm-darwin-amd64-$NANOMDM_VERSION.zip"
    unzip "nanomdm-darwin-amd64-$NANOMDM_VERSION.zip"
else
    echo "✅ NanoMDM déjà présent, téléchargement ignoré."
fi

# === ngrok ===
if ! command -v ngrok >/dev/null 2>&1; then
    echo "⚠️  ngrok non trouvé. Téléchargement..."
    curl -LO https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-darwin-amd64.zip
    unzip ngrok-stable-darwin-amd64.zip
    if [ -w /usr/local/bin ]; then
        mv ngrok /usr/local/bin/
        echo "✅ ngrok installé dans /usr/local/bin"
    else
        echo "⛔️ Permission refusée pour déplacer ngrok dans /usr/local/bin"
        echo "➡️  Lance cette commande manuellement : sudo mv ngrok /usr/local/bin/"
    fi
else
    echo "✅ ngrok est déjà installé."
fi

echo "✅ Installation terminée ! Tu peux maintenant configurer NanoMDM 🎉"
