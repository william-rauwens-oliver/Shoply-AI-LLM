# LLM Chat

Complete LLM chat application suite with native desktop client and command-line interfaces.

## Components

### 1. Desktop Application (`app/`)

Native cross-platform application built with Tauri and React.

**Features:**
- Compiled native binaries for macOS (.app) and Windows (.exe)
- Apple Silicon M3 Pro optimization with Metal GPU
- Real-time chat interface
- Model selection and parameter tuning
- Zero web browser dependency

**Platforms:**
- macOS 11+ (Apple Silicon, Intel)
- Windows 10+

**Development:**
```bash
cd app
npm install
npm run tauri:dev
```

**Production Build:**
```bash
npm run tauri:build
```

### 2. Command-Line Interfaces (`models/`)

Pure Python and Julia implementations for server or CLI usage.

**Python CLI:**
```bash
cd models/python-cli
python llm_demo.py --mode chat --system "You are helpful"
```

**Julia CLI:**
```bash
cd models/julia-cli
julia llm_demo.jl --mode=chat --enable-memory
```

## Architecture

```
LLM Chat/
├── app/                    # Desktop application
│   ├── src/               # React frontend
│   ├── src-tauri/         # Tauri (Rust) framework
│   └── server/            # FastAPI backend
├── models/                # CLI implementations
│   ├── python-cli/        # Python with FastAPI
│   └── julia-cli/         # Julia with Transformers.jl
└── README.md              # This file
```

## Quick Start

### Desktop Application

**Requirements:**
- Node.js 18+
- Python 3.10+
- Rust 1.60+

**Development:**
```bash
cd app
npm install
cd server && pip install -r requirements.txt
# Terminal 1: cd server && ./run.sh
# Terminal 2: npm run tauri:dev
```

**Build native binary:**
```bash
npm run tauri:build
```

### Command-Line

**Python:**
```bash
cd models/python-cli
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python llm_demo.py --mode chat
```

**Julia:**
```bash
cd models/julia-cli
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia llm_demo.jl --mode=chat
```

## Supported Models

All implementations support:
- `sshleifer/tiny-gpt2` - Lightweight, fast
- `distilgpt2` - Balanced
- `gpt2` - Full-size

## GPU Support

Automatic detection and optimization for:
- Apple Metal (Apple Silicon)
- CUDA (NVIDIA)
- CPU fallback

## Documentation

- **Desktop App:** See `app/README.md`
- **Python CLI:** See `models/python-cli/llm_demo.py`
- **Julia CLI:** See `models/julia-cli/llm_demo.jl`
- **Quick Start:** See `QUICKSTART.md`

## Performance (M3 Pro)

| Model | Device | Time |
|-------|--------|------|
| tiny-gpt2 | Metal | 1-2s |
| distilgpt2 | Metal | 2-4s |
| gpt2 | Metal | 4-8s |

## License

MIT

## Requirements

### macOS
- macOS 11+
- Xcode Command Line Tools: `xcode-select --install`
- Homebrew (for Python): `brew install python`

### Windows
- Windows 10+
- Visual Studio Build Tools
- Python from python.org

### All Platforms
- Node.js 18+
- Rust: https://rustup.rs
