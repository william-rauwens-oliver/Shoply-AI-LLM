# LLM Models - CLI Implementations

Command-line interfaces for LLM models in Python and Julia.

## Structure

- `python-cli/` - Python implementation with FastAPI integration
- `julia-cli/` - Julia implementation with Transformers.jl

## Python CLI

### Installation
```bash
cd python-cli
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Single prompt mode
```bash
python llm_demo.py --prompt "Hello" --model sshleifer/tiny-gpt2
```

### Interactive chat mode
```bash
python llm_demo.py --mode chat --enable-memory
```

### With system prompt
```bash
python llm_demo.py --mode chat --system "You are a helpful assistant" --save-history chat.json
```

## Julia CLI

### Installation
```bash
cd julia-cli
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Single prompt mode
```bash
julia llm_demo.jl --prompt="Hello"
```

### Interactive chat mode
```bash
julia llm_demo.jl --mode=chat --enable-memory
```

## Features

- Conversation mode with persistent history
- Long-term memory for thematic continuity
- JSON history export/import
- Configurable models and parameters
- Apple Silicon GPU support
