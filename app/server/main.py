import logging
from typing import Optional

import torch
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from transformers import pipeline

logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

# Device detection
if torch.backends.mps.is_available():
    DEVICE = "mps"
    logger.info("Apple Silicon detected - using Metal GPU")
else:
    DEVICE = "cpu"
    logger.info("Using CPU")

# Model cache
_model_cache = {}


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    system: str = Field(default="You are a helpful AI assistant.")
    model: str = Field(default="sshleifer/tiny-gpt2")
    temperature: float = Field(default=0.8, ge=0.1, le=2.0)
    max_tokens: int = Field(default=80, ge=10, le=200)


class ChatResponse(BaseModel):
    response: str
    tokens_used: int
    model: str


class HealthResponse(BaseModel):
    status: str
    device: str
    metal_available: bool


app = FastAPI(title="LLM Chat Server", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_model(model_name: str):
    """Load or retrieve cached model"""
    if model_name not in _model_cache:
        logger.info(f"Loading model: {model_name}")
        _model_cache[model_name] = pipeline(
            "text-generation",
            model=model_name,
            device=0 if DEVICE == "mps" else -1,
        )
    return _model_cache[model_name]


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint"""
    return HealthResponse(
        status="ok",
        device=DEVICE,
        metal_available=torch.backends.mps.is_available(),
    )


@app.post("/api/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """Main chat endpoint"""
    try:
        generator = get_model(req.model)

        prompt = f"{req.system}\n\nUser: {req.message}\nAssistant:"

        outputs = generator(
            prompt,
            max_new_tokens=req.max_tokens,
            do_sample=True,
            temperature=req.temperature,
            top_k=50,
            top_p=0.95,
        )

        response_text = outputs[0]["generated_text"]

        if "Assistant:" in response_text:
            response_text = response_text.split("Assistant:")[-1].strip()

        return ChatResponse(
            response=response_text[:500],
            tokens_used=req.max_tokens,
            model=req.model,
        )
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/models/clear-cache")
async def clear_cache():
    """Clear model cache"""
    _model_cache.clear()
    logger.info("Model cache cleared")
    return {"status": "cache cleared"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=7860, log_level="info")
