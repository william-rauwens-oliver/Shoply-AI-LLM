# 🚀 Démarrage rapide - LLM AI Chat App

## 1️⃣ Installation (une seule fois)

```bash
# Naviguer vers le dossier app
cd /Users/WilliamPro/Downloads/test/llm-app

# Installer les dépendances Node
npm install

# Installer les dépendances Python
cd backend
pip install -r requirements.txt
cd ..
```

**Durée** : ~5-10 minutes (selon la connexion internet)

## 2️⃣ Lancer l'app

### ✨ La plus simple (macOS/Linux) :
```bash
cd /Users/WilliamPro/Downloads/test/llm-app
./start.sh
```

**C'est tout !** L'app s'ouvre automatiquement.

---

### 📌 Alternative (2 terminaux) :

**Terminal 1 - Backend LLM** :
```bash
cd /Users/WilliamPro/Downloads/test/llm-app/backend
./run.sh
# Devrait afficher: ✅ Serveur lancé sur http://localhost:7860
```

**Terminal 2 - Interface** :
```bash
cd /Users/WilliamPro/Downloads/test/llm-app
npm run tauri:dev
# L'app s'ouvre dans une fenêtre native
```

---

## 3️⃣ Utilisation

1. **Interface apparaît** avec un chat noir/bleu moderne
2. **Choisissez le modèle** à gauche (tiny-gpt2 par défaut = rapide)
3. **Tapez votre message** en bas
4. **Appuyez Entrée** ou cliquez 📤
5. **L'IA répond** en utilisant votre **M3 Pro Metal GPU** 🍎

---

## ⚡ Performance sur M3 Pro

| Modèle | Temps | Utilisation GPU |
|--------|-------|-----------------|
| tiny-gpt2 | ⚡ 1-2 sec | 🟢 Très léger |
| distilgpt2 | ⚡⚡ 2-4 sec | 🟢 Léger |
| gpt2 | ⚡⚡⚡ 4-8 sec | 🟡 Moyen |

---

## 🛠️ Dépannage

### ❌ "Le serveur LLM n'est pas accessible"
✅ **Solution** : Lancez d'abord le backend dans Terminal 1

### ❌ App crashe au démarrage
✅ **Solution** : 
```bash
# Supprimez et réinstallez les node_modules
rm -rf node_modules
npm install
```

### ❌ Python n'est pas trouvé
✅ **Solution** : Installez Python via Homebrew
```bash
brew install python
```

### ⚠️ Premier chargement lent (normal)
- Première fois : le modèle se télécharge (~200 MB)
- Prochaines fois : rapide (modèle en cache)

---

## 📂 Structure

```
llm-app/
├── backend/           ← Serveur LLM (FastAPI + PyTorch)
│   ├── main.py       ← Cœur du serveur
│   └── run.sh        ← Script lancement
├── src/              ← Interface (React)
│   ├── App.jsx       ← Chat UI
│   └── App.css       ← Styles
├── start.sh          ← Lancement auto (tout en 1)
├── README.md         ← Documentation complète
└── package.json      ← Dépendances Node
```

---

## 🍎 Optimisation Apple Silicon

L'app détecte automatiquement votre M3 Pro et utilise :
- ✅ **Metal GPU** si disponible (rapide)
- ✅ **CPU** en fallback (compatible)

Visible dans le backend log :
```
🍎 Apple Silicon (Metal) détecté - utilisation du GPU
```

---

## 🔧 Commandes utiles

```bash
# Développement avec rechargement auto
npm run tauri:dev

# Builder l'app native (Mac/Windows)
npm run tauri:build

# Vérifier la santé du serveur
curl http://localhost:7860/health

# Vider le cache des modèles
curl -X POST http://localhost:7860/api/clear-cache
```

---

## 📖 Plus d'infos

- **README complet** : `llm-app/README.md`
- **Code frontend** : `llm-app/src/App.jsx`
- **Code backend** : `llm-app/backend/main.py`

---

## 💡 Conseils

✨ **Pour une meilleure expérience** :
1. Gardez le backend lancé en arrière-plan
2. Utilisez `tiny-gpt2` pour tester (très rapide)
3. Augmentez `Température` pour des réponses plus créatives
4. Modifiez les "Instructions système" pour personnaliser l'IA

---

**Bon usage ! 🚀**
