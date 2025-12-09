#!/bin/bash

# Script de lancement du backend LLM
# Détecte Python et Lance le serveur

echo "🚀 Démarrage du serveur LLM..."

# Cherche Python3
if command -v python3 &> /dev/null; then
    PYTHON=python3
elif command -v python &> /dev/null; then
    PYTHON=python
else
    echo "❌ Python non trouvé"
    exit 1
fi

# Vérifier le venv
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Création de l'environnement virtuel..."
    $PYTHON -m venv "$VENV_DIR"
fi

# Activer le venv
source "$VENV_DIR/bin/activate"

# Installer les dépendances
echo "📥 Vérification des dépendances..."
pip install -q -r requirements.txt

# Lancer le serveur
echo "✅ Serveur lancé sur http://localhost:7860"
$PYTHON main.py
