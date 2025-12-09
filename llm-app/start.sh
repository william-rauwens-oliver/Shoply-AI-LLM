#!/bin/bash

# Script de lancement complet de l'app LLM
# Lance le backend et le frontend simultanément

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"

echo "🚀 LLM AI Chat - Lancement complet"
echo "=================================="

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js non trouvé. Installez depuis https://nodejs.org"
    exit 1
fi

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 non trouvé. Installez depuis https://www.python.org"
    exit 1
fi

echo "✅ Dépendances détectées"

# Lancer le backend en arrière-plan
echo ""
echo "📦 Démarrage du backend LLM (port 7860)..."
cd "$BACKEND_DIR"

# Créer venv si nécessaire
if [ ! -d ".venv" ]; then
    echo "   Création de l'environnement virtuel..."
    python3 -m venv .venv
fi

# Activer venv et installer
source .venv/bin/activate
pip install -q -r requirements.txt

# Lancer le serveur en arrière-plan
python main.py &
BACKEND_PID=$!
echo "✅ Backend lancé (PID: $BACKEND_PID)"

# Retour au dossier principal
cd "$SCRIPT_DIR"

# Attendre que le backend soit prêt
echo ""
echo "⏳ Attente du serveur Backend..."
sleep 3

# Vérifier que le backend répond
if curl -s http://localhost:7860/health > /dev/null 2>&1; then
    echo "✅ Backend opérationnel"
else
    echo "⚠️  Backend lent à démarrer, continuant..."
fi

# Lancer le frontend
echo ""
echo "🎨 Démarrage de l'interface (http://localhost:5173)..."
npm run tauri:dev

# Cleanup
trap "kill $BACKEND_PID" EXIT
