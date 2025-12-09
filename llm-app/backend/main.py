from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import pipeline
import uvicorn
import torch
import logging

# Configuration
MODEL_CACHE = {}
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# Détection Metal (Apple Silicon)
if torch.backends.mps.is_available():
    device = "mps"
    logger.info("🍎 Apple Silicon (Metal) détecté - utilisation du GPU")
else:
    device = "cpu"
    logger.info("⚠️ Apple Silicon non disponible, utilisation du CPU")

app = FastAPI(title="LLM AI Backend")

# CORS pour l'app Tauri
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str
    system: str = "Tu es un assistant IA utile."
    model: str = "sshleifer/tiny-gpt2"
    temperature: float = 0.8
    max_tokens: int = 80


class ChatResponse(BaseModel):
    response: str
    tokens_used: int


def get_generator(model_name: str):
    """Cache et retourne un pipeline."""
    if model_name not in MODEL_CACHE:
        logger.info(f"📦 Chargement du modèle {model_name}...")
        MODEL_CACHE[model_name] = pipeline(
            "text-generation",
            model=model_name,
            device=0 if device == "mps" else -1,
        )
    return MODEL_CACHE[model_name]


@app.post("/api/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """Endpoint de chat principal."""
    try:
        generator = get_generator(req.model)
        
        # Construit le prompt
        prompt = f"{req.system}\n\nMessage: {req.message}\nRéponse:"
        
        # Génère
        outputs = generator(
            prompt,
            max_new_tokens=req.max_tokens,
            do_sample=True,
            temperature=req.temperature,
            top_k=50,
            top_p=0.95,
        )
        
        response_text = outputs[0]["generated_text"]
        # Extrait la réponse
        if "Réponse:" in response_text:
            response_text = response_text.split("Réponse:")[-1].strip()
        
        return ChatResponse(
            response=response_text[:500],  # Limite à 500 chars
            tokens_used=req.max_tokens,
        )
    except Exception as e:
        logger.error(f"❌ Erreur: {e}")
        return ChatResponse(
            response=f"Erreur: {str(e)}",
            tokens_used=0,
        )


@app.get("/health")
async def health():
    """Health check."""
    return {
        "status": "ok",
        "device": device,
        "metal_available": torch.backends.mps.is_available(),
        "cuda_available": torch.cuda.is_available(),
    }


@app.post("/api/clear-cache")
async def clear_cache():
    """Vide le cache des modèles."""
    MODEL_CACHE.clear()
    return {"status": "cache cleared"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=7860, log_level="info")
