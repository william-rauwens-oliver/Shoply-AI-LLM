import argparse
from transformers import pipeline, AutoModelForCausalLM, AutoTokenizer
import time
import sys
from pathlib import Path
import json


# Cache pour les modèles chargés
_model_cache = {}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Demo LLM conversationnel avancé avec GPT-2",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Exemples:
  python llm_demo.py --prompt "Bonjour"
  python llm_demo.py --mode chat  # mode interactif
  python llm_demo.py --model distilgpt2 --max-tokens 150 --system "Tu es un assistant"
  python llm_demo.py --save-history chat.json --enable-memory
        """,
    )
    parser.add_argument("--prompt", default="", help="Texte initial (ignore mode chat)")
    parser.add_argument(
        "--model",
        default="sshleifer/tiny-gpt2",
        help="Modèle Hugging Face (tiny-gpt2, distilgpt2, gpt2)",
    )
    parser.add_argument("--max-tokens", type=int, default=80, help="Tokens max générés")
    parser.add_argument(
        "--temperature", type=float, default=0.8, help="Contrôle créativité (0.1-2.0)"
    )
    parser.add_argument("--top-k", type=int, default=50, help="Top-k sampling")
    parser.add_argument("--top-p", type=float, default=0.95, help="Top-p (nucleus) sampling")
    parser.add_argument(
        "--mode",
        choices=["single", "chat"],
        default="single",
        help="single: un prompt, chat: conversation interactive",
    )
    parser.add_argument(
        "--system",
        default="",
        help="Instructions système pour façonner le comportement de l'IA"
    )
    parser.add_argument(
        "--save-history",
        default="",
        help="Sauvegarder l'historique du chat dans un fichier JSON"
    )
    parser.add_argument(
        "--load-history",
        default="",
        help="Charger l'historique d'un fichier JSON"
    )
    parser.add_argument(
        "--enable-memory",
        action="store_true",
        help="Activer la mémoire long-terme (conserve les thèmes)"
    )
    return parser


def generate_text(generator, text: str, args) -> str:
    """Génère du texte avec timing et contrôle de qualité."""
    try:
        start = time.time()
        outputs = generator(
            text,
            max_new_tokens=args.max_tokens,
            do_sample=True,
            top_k=args.top_k,
            top_p=args.top_p,
            temperature=args.temperature,
            pad_token_id=50256,  # Prévient les avertissements
        )
        elapsed = time.time() - start
        result = outputs[0]["generated_text"]
        return result, elapsed
    except Exception as e:
        print(f"❌ Erreur de génération: {e}", file=sys.stderr)
        return None, 0


def build_system_prompt(system_instruction: str, history_context: str = "") -> str:
    """Construit un prompt système amélioré."""
    if system_instruction:
        base = system_instruction
    else:
        base = "Tu es un assistant IA utile, honnête et inoffensif. Tu répondras en français."
    
    if history_context:
        base += f"\n\nContexte précédent:\n{history_context}"
    
    return base


def extract_keywords(text: str) -> list:
    """Extrait les mots clés importants pour la mémoire long-terme."""
    common_words = {"le", "la", "de", "et", "ou", "est", "un", "une", "à", "en", "je", "tu", "il", "elle"}
    words = text.lower().split()
    return [w for w in words if len(w) > 3 and w not in common_words]


def single_mode(args):
    """Mode avec un seul prompt."""
    if not args.prompt:
        args.prompt = "Bonjour, je suis une IA intelligente et je peux"

    print(f"\n📦 Chargement du modèle '{args.model}'...")
    generator = pipeline("text-generation", model=args.model)

    print(f"✨ Génération en cours...\n")
    result, elapsed = generate_text(generator, args.prompt, args)

    if result:
        print(f"📝 Prompt:\n{args.prompt}")
        print(f"\n🤖 Réponse:\n{result}")
        print(f"\n⏱️  Temps: {elapsed:.2f}s | Tokens max: {args.max_tokens} | Temp: {args.temperature}")


def chat_mode(args):
    """Mode conversation multi-tour avec mémoire et historique."""
    print(f"\n📦 Chargement du modèle '{args.model}'...")
    generator = pipeline("text-generation", model=args.model)

    history = []
    memory = {"topics": [], "entities": []}
    token_count = 0
    start_time = time.time()
    
    # Charger historique si demandé
    if args.load_history and Path(args.load_history).exists():
        try:
            with open(args.load_history) as f:
                data = json.load(f)
                history = data.get("history", [])
                memory = data.get("memory", memory)
            print(f"📂 Historique chargé ({len(history)} messages)\n")
        except Exception as e:
            print(f"⚠️  Impossible de charger l'historique: {e}\n")

    print(
        "💬 Mode conversation (tapez 'quit' pour quitter, 'clear' pour réinitialiser, 'mem' pour voir la mémoire)\n"
    )

    while True:
        try:
            user_input = input("👤 Vous: ").strip()
        except (EOFError, KeyboardInterrupt):
            break

        if user_input.lower() == "quit":
            break
        elif user_input.lower() == "clear":
            history = []
            memory = {"topics": [], "entities": []}
            token_count = 0
            print("🗑️  Historique et mémoire effacés.\n")
            continue
        elif user_input.lower() == "mem":
            print(f"\n💾 Mémoire: Thèmes={memory['topics'][-3:]}, Entités={memory['entities'][-3:]}\n")
            continue
        elif not user_input:
            continue

        # Construit contexte avec historique (limité) et système
        context_msgs = " ".join([msg for pair in history[-2:] for msg in pair])
        system = build_system_prompt(args.system, context_msgs[:200] if context_msgs else "")
        prompt = f"{system}\n\nConversation:\n{context_msgs}\n👤 Vous: {user_input}\n🤖 IA:"

        result, elapsed = generate_text(generator, prompt, args)

        if result:
            # Extrait réponse nouvelle
            response = result.split("🤖 IA:")[-1].strip() if "🤖 IA:" in result else result
            response = response[:200]  # Limite la réponse
            
            print(f"🤖 IA: {response}\n")
            history.append((user_input, response))
            
            # Mise à jour de la mémoire si activée
            if args.enable_memory:
                keywords = extract_keywords(user_input) + extract_keywords(response)
                memory["topics"].extend(keywords[-3:])
                memory["topics"] = list(set(memory["topics"]))[-10:]  # Garde 10 thèmes max
            
            token_count += args.max_tokens
        else:
            print("⚠️  Erreur lors de la génération.\n")

    # Sauvegarder historique si demandé
    if args.save_history:
        try:
            with open(args.save_history, "w") as f:
                json.dump({"history": history, "memory": memory}, f, indent=2, ensure_ascii=False)
            print(f"\n💾 Historique sauvegardé dans {args.save_history}")
        except Exception as e:
            print(f"\n⚠️  Impossible de sauvegarder: {e}")

    # Stats finales
    total_time = time.time() - start_time
    print(f"\n📊 Stats: {len(history)} échanges, ~{token_count} tokens, {total_time:.1f}s total")
    print(f"🧠 Mémoire: {len(memory['topics'])} thèmes conservés")


def main():
    args = build_parser().parse_args()

    if args.mode == "chat":
        chat_mode(args)
    else:
        single_mode(args)


if __name__ == "__main__":
    main()
