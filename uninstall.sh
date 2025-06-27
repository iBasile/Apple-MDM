#!/bin/bash

# 🔐 Exiger sudo
if [ "$EUID" -ne 0 ]; then
  echo "🔐 Ce script doit être exécuté en tant qu'administrateur. Relance avec sudo..."
  exec sudo "$0" "$@"
fi

INSTALL_DIR="$HOME/nanomdm-setup"
BIN_DIR="/usr/local/bin"
NGROK_PATH="$BIN_DIR/ngrok"

echo "🧼 Désinstallation de NanoMDM et de son environnement..."

# 🗑 Supprimer le dossier d'installation
if [ -d "$INSTALL_DIR" ]; then
  echo "📁 Suppression du dossier $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
else
  echo "⚠️  Aucun dossier d'installation trouvé à $INSTALL_DIR"
fi

# 🗑 Supprimer ngrok s'il a été installé par le script
if [ -f "$NGROK_PATH" ]; then
  echo "🔌 Suppression de ngrok depuis $NGROK_PATH"
  rm -f "$NGROK_PATH"
else
  echo "✅ ngrok n'était pas installé à $NGROK_PATH (peut-être déjà supprimé ou installé manuellement)"
fi

# 🔄 Nettoyage des fichiers de configuration éventuels
echo "🧹 Vérification de la présence de fichiers .crt, .key, .db..."
find "$HOME" -type f \( -name "*.crt" -o -name "*.key" -o -name "*.db" \) -delete

echo "✅ Désinstallation complète terminée."
