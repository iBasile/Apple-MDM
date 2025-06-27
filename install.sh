#!/bin/bash

set -e

echo "🛠️  Bienvenue dans l'installateur NanoMDM pour macOS"

# Vérification des dépendances
for cmd in curl unzip openssl; do
    if ! command -v $cmd &>/dev/null; then
        echo "❌ $cmd est requis mais non installé."
        exit 1
    fi
done

# Répertoire d'installation
BASE_DIR="$HOME/nanomdm-setup"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

echo "📁 Dossier d'installation : $BASE_DIR"

# Téléchargement des binaires SCEP
echo "⬇️  Téléchargement de SCEP Server..."
mkdir -p scep && cd scep
curl -LO https://github.com/micromdm/scep/releases/download/v2.1.0/scepserver-darwin-amd64-v2.1.0.zip
unzip -o scepserver-darwin-amd64-v2.1.0.zip
chmod +x scepserver-darwin-amd64
./scepserver-darwin-amd64 ca -init
cd ..

# Téléchargement de NanoMDM
echo "⬇️  Téléchargement de NanoMDM..."
mkdir -p nanomdm && cd nanomdm
curl -LO https://github.com/micromdm/nanomdm/releases/download/v0.2.0/nanomdm-darwin-amd64-v0.2.0.zip
unzip -o nanomdm-darwin-amd64-v0.2.0.zip
chmod +x nanomdm-darwin-amd64
cd ..

# Téléchargement de ngrok si absent
if ! command -v ngrok &>/dev/null; then
    echo "⚠️  ngrok non trouvé. Téléchargement..."
    curl -LO https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-darwin-amd64.zip
    unzip -o ngrok-stable-darwin-amd64.zip
    mv ngrok /usr/local/bin/
fi

# Lancement du serveur SCEP
read -p "🔐 Entrez un mot de passe 'challenge' pour SCEP (ex: nanomdm) : " SCEP_CHALLENGE
echo "🚀 Lancement du serveur SCEP..."
cd "$BASE_DIR/scep"
./scepserver-darwin-amd64 -allowrenew 0 -challenge "$SCEP_CHALLENGE" -debug &
SCEP_PID=$!
cd "$BASE_DIR"
sleep 2

# Tunnel ngrok pour SCEP
echo "🌐 Création d'un tunnel ngrok pour SCEP (port 8080)..."
ngrok http 8080 > scep-ngrok.log &
sleep 5
SCEP_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[a-z0-9]*\.ngrok\.io' | head -n1)
echo "🔗 SCEP URL : $SCEP_URL"

# Récupération du certificat CA
echo "📄 Récupération du certificat CA de SCEP..."
curl "$SCEP_URL/scep?operation=GetCACert" --output ca.der
openssl x509 -inform DER -in ca.der -out ca.pem

# Lancement NanoMDM
read -p "🔑 Clé API pour NanoMDM (défaut : nanomdm) : " API_KEY
API_KEY=${API_KEY:-nanomdm}
echo "🚀 Lancement de NanoMDM..."
cd "$BASE_DIR/nanomdm"
./nanomdm-darwin-amd64 -ca ../ca.pem -api "$API_KEY" -debug &
MDM_PID=$!
cd "$BASE_DIR"
sleep 2

# Tunnel ngrok pour NanoMDM
echo "🌐 Création d'un tunnel ngrok pour NanoMDM (port 9000)..."
ngrok http 9000 > mdm-ngrok.log &
sleep 5
MDM_URL=$(curl -s http://127.0.0.1:4041/api/tunnels | grep -o 'https://[a-z0-9]*\.ngrok\.io' | head -n1)
echo "🔗 NanoMDM URL : $MDM_URL"

# Upload certificat push
read -p "📁 Entrez le chemin du certificat push (.pem) : " PUSH_CERT
read -p "📁 Entrez le chemin de la clé privée push (.key) : " PUSH_KEY
cat "$PUSH_CERT" "$PUSH_KEY" | curl -T - -u nanomdm:"$API_KEY" "$MDM_URL/v1/pushcert"

echo ""
echo "✅ INSTALLATION TERMINÉE"
echo "👉 Profil d'enrôlement à générer avec les infos suivantes :"
echo "   🔐 SCEP Challenge : $SCEP_CHALLENGE"
echo "   🔗 SCEP URL       : $SCEP_URL/scep"
echo "   🌍 MDM ServerURL  : $MDM_URL/mdm"
echo "   📌 API Key        : $API_KEY"
echo ""
echo "💡 Envoie un profil .mobileconfig à tes appareils avec ces paramètres pour l'enrôlement."
echo ""
