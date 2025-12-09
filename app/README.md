# LLM Chat Application

Professional native desktop application for Mac and Windows with integrated LLM.

## Features

- Native application (compiled to .app on macOS, .exe on Windows)
- Apple Silicon M3 Pro optimization with Metal GPU support
- React-based modern UI
- Real-time LLM chat with model selection
- Configurable system prompts and parameters
- Cross-platform Tauri framework

## Requirements

### macOS
- macOS 11+
- Apple Silicon or Intel
- Node.js 18+
- Python 3.10+
- Rust 1.60+
- Xcode Command Line Tools: `xcode-select --install`

### Windows
- Windows 10+
- Node.js 18+
- Python 3.10+
- Rust 1.60+
- Visual Studio Build Tools

## Installation

### 1. Install Node dependencies
```bash
npm install
```

### 2. Install Python dependencies
```bash
cd server
pip install -r requirements.txt
cd ..
```

## Development

### Terminal 1 - Start backend server
```bash
cd server
./run.sh
```

### Terminal 2 - Start development app
```bash
npm run tauri:dev
```

## Building

### macOS (creates .app bundle)
```bash
npm run tauri:build
# Output: src-tauri/target/release/bundle/macos/LLM Chat.app
```

### Windows (creates .exe installer)
```bash
npm run tauri:build
# Output: src-tauri/target/release/LLM-Chat_0.1.0_x64_en-US.msi
```

## Production Deployment

Distribution files are created in:
- macOS: `src-tauri/target/release/bundle/macos/`
- Windows: `src-tauri/target/release/bundle/msi/`

## Architecture

- **Frontend**: React 18 + Vite
- **Desktop**: Tauri (Rust)
- **Backend**: FastAPI + PyTorch
- **AI Models**: Hugging Face Transformers

## Performance

Apple Silicon M3 Pro with Metal GPU:
- tiny-gpt2: ~1-2 seconds per response
- distilgpt2: ~2-4 seconds per response
- gpt2: ~4-8 seconds per response

## License

MIT
