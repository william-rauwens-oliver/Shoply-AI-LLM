import argparse
from transformers import pipeline
import time
import sys


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Demo LLM conversationnel avec GPT-2",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Exemples:
  python llm_demo.py --prompt "Bonjour"
  python llm_demo.py --mode chat  # mode interactif
  python llm_demo.py --model distilgpt2 --max-tokens 150
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
    return parser


def generate_text(generator, text: str, args) -> str:
    """Génère du texte avec timing."""
    try:
        start = time.time()
        outputs = generator(
            text,
            max_new_tokens=args.max_tokens,
            do_sample=True,
            top_k=args.top_k,
            top_p=args.top_p,
            temperature=args.temperature,
        )
        elapsed = time.time() - start
        result = outputs[0]["generated_text"]
        return result, elapsed
    except Exception as e:
        print(f"❌ Erreur de génération: {e}", file=sys.stderr)
        return None, 0


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
    """Mode conversation multi-tour avec historique."""
    print(f"\n📦 Chargement du modèle '{args.model}'...")
    generator = pipeline("text-generation", model=args.model)

    history = []
    token_count = 0
    start_time = time.time()

    print(
        "\n💬 Mode conversation (tapez 'quit' pour quitter, 'clear' pour réinitialiser)\n"
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
            token_count = 0
            print("🗑️  Historique effacé.\n")
            continue
        elif not user_input:
            continue

        # Construit contexte avec historique (limite à ~500 chars pour éviter overflow)
        context = " ".join([msg for pair in history[-3:] for msg in pair])
        prompt = context + " " + user_input if context else user_input

        result, elapsed = generate_text(generator, prompt, args)

        if result:
            # Extrait la réponse nouvelle (après le prompt)
            response = result[len(prompt) :].strip() if len(result) > len(prompt) else result
            print(f"🤖 IA: {response}\n")
            history.append((user_input, response))
            token_count += args.max_tokens
        else:
            print("⚠️  Erreur lors de la génération.\n")

    # Stats finales
    total_time = time.time() - start_time
    print(f"\n📊 Stats: {len(history)} échanges, ~{token_count} tokens, {total_time:.1f}s total")


def main():
    args = build_parser().parse_args()

    if args.mode == "chat":
        chat_mode(args)
    else:
        single_mode(args)


if __name__ == "__main__":
    main()
