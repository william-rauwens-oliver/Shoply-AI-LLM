# Quick Start - LLM AI Chat App

## Installation (one-time setup)

```bash
# Navigate to app directory
cd /Users/WilliamPro/Downloads/test/app

# Install Node dependencies
npm install

# Install Python dependencies
cd server
pip install -r requirements.txt
cd ..
```

**Duration**: ~5-10 minutes depending on connection speed

## Launch the App

### Recommended (macOS/Linux):
```bash
cd /Users/WilliamPro/Downloads/test/app
./run.sh
```

The app opens automatically.

---

### Alternative (two terminals):

**Terminal 1 - Backend Server**:
```bash
cd /Users/WilliamPro/Downloads/test/app/server
./run.sh
# Should display: Server started on http://localhost:7860
```

**Terminal 2 - Interface**:
```bash
cd /Users/WilliamPro/Downloads/test/app
npm run tauri:dev
# App opens in native window
```

---

## Usage

1. Interface opens with modern dark/blue chat theme
2. Select model on left (tiny-gpt2 default = fastest)
3. Type message at bottom
4. Press Enter or click Send
5. AI responds using your M3 Pro Metal GPU

---

## Performance on M3 Pro

| Model | Time | GPU Usage |
|-------|------|-----------|
| tiny-gpt2 | 1-2 sec | Very light |
| distilgpt2 | 2-4 sec | Light |
| gpt2 | 4-8 sec | Medium |

---

## Troubleshooting

### "LLM server not accessible"
**Solution**: Start backend in Terminal 1 first

### App crashes on startup
**Solution**: 
```bash
rm -rf node_modules
npm install
```

### Python not found
**Solution**: Install via Homebrew
```bash
brew install python
```

### First load is slow (normal)
- First time: model downloads (~200 MB)
- Later: cached model loads quickly

---

## Directory Structure

```
app/
├── server/           <- LLM server (FastAPI + PyTorch)
│   ├── main.py      <- Server core
│   └── run.sh       <- Launch script
├── src/             <- Interface (React)
│   ├── App.jsx      <- Chat UI
│   └── App.css      <- Styles
├── run.sh           <- Auto-launch
├── README.md        <- Full documentation
└── package.json     <- Node dependencies
```

---

## Apple Silicon Optimization

App auto-detects M3 Pro and uses:
- Metal GPU when available (fast)
- CPU fallback for compatibility

See in backend logs:
```
Apple Silicon (Metal) detected - using GPU
```

---

## Useful Commands

```bash
# Development with hot reload
npm run tauri:dev

# Build native app (Mac/Windows)
npm run tauri:build

# Check server health
curl http://localhost:7860/health

# Clear model cache
curl -X POST http://localhost:7860/api/clear-cache
```

---

## More Information

- **Full README**: `app/README.md`
- **Frontend code**: `app/src/App.jsx`
- **Backend code**: `app/server/main.py`

---

## Tips for Best Experience

1. Keep backend running in background
2. Use `tiny-gpt2` for testing (very fast)
3. Increase Temperature for more creative responses
4. Modify System Instructions to customize AI behavior
