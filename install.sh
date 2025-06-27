#!/bin/bash

# 🔐 Exécuter en sudo
if [ "$EUID" -ne 0 ]; then
  echo "🔐 Ce script nécessite les droits administrateur. Relance avec sudo..."
  exec sudo "$0" "$@"
fi

echo "🛠️  Bienvenue dans l'installateur NanoMDM pour macOS"

INSTALL_DIR="$HOME/nanomdm-setup"
BIN_DIR="/usr/local/bin"

# 🧹 Nettoyage si une ancienne installation existe
if [ -d "$INSTALL_DIR" ]; then
  echo "🧹 Nettoyage de l'ancienne installation dans $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# ⬇️ Télécharger le serveur SCEP
echo "⬇️  Téléchargement de SCEP Server..."
SCEP_VERSION="v2.1.0"
curl -fsSL -o scepserver.zip "https://github.com/micromdm/scep/releases/download/${SCEP_VERSION}/scepserver-darwin-amd64-${SCEP_VERSION}.zip"
unzip -o scepserver.zip
mv scepserver-darwin-amd64 scepserver

# ⬇️ Télécharger NanoMDM
echo "⬇️  Téléchargement de NanoMDM..."
NANOMDM_VERSION="v0.2.0"
curl -fsSL -o nanomdm.zip "https://github.com/micromdm/nanomdm/releases/download/${NANOMDM_VERSION}/nanomdm-darwin-amd64-${NANOMDM_VERSION}.zip"
unzip -o nanomdm.zip
mv nanomdm-darwin-amd64 nanomdm

# ⬇️ Télécharger ngrok si absent
if ! command -v ngrok &>/dev/null; then
  echo "⚠️  ngrok non trouvé. Téléchargement..."
  curl -fsSL -o ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-darwin-amd64.zip
  unzip -o ngrok.zip
  mv ngrok "$BIN_DIR/ngrok" || sudo mv ngrok "$BIN_DIR/ngrok"
  chmod +x "$BIN_DIR/ngrok"
fi

# ✅ Initialisation du CA SCEP
echo "🔐 Initialisation d'une autorité de certification SCEP"
./scepserver -initca -key ca.key -cert ca.crt -organization "BargiCorp" -country FR

echo ""
echo "✅ Installation terminée."
echo "📂 Dossier d'installation : $INSTALL_DIR"
echo "👉 Lancez ./nanomdm ou ./scepserver pour démarrer les services."
