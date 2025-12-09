import argparse
from transformers import pipeline
import time
import sys
from pathlib import Path
import json


_model_cache = {}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="LLM Chat Application",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python llm_demo.py --prompt "Hello"
  python llm_demo.py --mode chat
  python llm_demo.py --model distilgpt2 --max-tokens 150 --system "You are helpful"
  python llm_demo.py --save-history chat.json --enable-memory
        """,
    )
    parser.add_argument("--prompt", default="", help="Initial text")
    parser.add_argument(
        "--model",
        default="sshleifer/tiny-gpt2",
        help="Hugging Face model name",
    )
    parser.add_argument("--max-tokens", type=int, default=80, help="Maximum tokens to generate")
    parser.add_argument(
        "--temperature", type=float, default=0.8, help="Temperature for sampling (0.1-2.0)"
    )
    parser.add_argument("--top-k", type=int, default=50, help="Top-k sampling parameter")
    parser.add_argument("--top-p", type=float, default=0.95, help="Top-p nucleus sampling")
    parser.add_argument(
        "--mode",
        choices=["single", "chat"],
        default="single",
        help="Execution mode",
    )
    parser.add_argument(
        "--system",
        default="",
        help="System prompt for AI behavior"
    )
    parser.add_argument(
        "--save-history",
        default="",
        help="Save chat history to JSON file"
    )
    parser.add_argument(
        "--load-history",
        default="",
        help="Load chat history from JSON file"
    )
    parser.add_argument(
        "--enable-memory",
        action="store_true",
        help="Enable long-term memory for topics"
    )
    return parser


def generate_text(generator, text: str, args):
    try:
        start = time.time()
        outputs = generator(
            text,
            max_new_tokens=args.max_tokens,
            do_sample=True,
            top_k=args.top_k,
            top_p=args.top_p,
            temperature=args.temperature,
            pad_token_id=50256,
        )
        elapsed = time.time() - start
        result = outputs[0]["generated_text"]
        return result, elapsed
    except Exception as e:
        print(f"Error generating text: {e}", file=sys.stderr)
        return None, 0


def build_system_prompt(system_instruction: str, history_context: str = "") -> str:
    if system_instruction:
        base = system_instruction
    else:
        base = "You are a helpful AI assistant."
    
    if history_context:
        base += f"\n\nPrevious context:\n{history_context}"
    
    return base


def extract_keywords(text: str) -> list:
    common_words = {"the", "a", "an", "and", "or", "is", "to", "in", "of", "you", "i", "we", "they"}
    words = text.lower().split()
    return [w for w in words if len(w) > 3 and w not in common_words]


def single_mode(args):
    if not args.prompt:
        args.prompt = "Hello, I am an AI assistant"

    print(f"\nLoading model '{args.model}'...")
    generator = pipeline("text-generation", model=args.model)

    print("Generating response...\n")
    result, elapsed = generate_text(generator, args.prompt, args)

    if result:
        print(f"Prompt:\n{args.prompt}")
        print(f"\nResponse:\n{result}")
        print(f"\nTime: {elapsed:.2f}s | Max tokens: {args.max_tokens} | Temperature: {args.temperature}")


def chat_mode(args):
    print(f"\nLoading model '{args.model}'...")
    generator = pipeline("text-generation", model=args.model)

    history = []
    memory = {"topics": [], "entities": []}
    token_count = 0
    start_time = time.time()
    
    if args.load_history and Path(args.load_history).exists():
        try:
            with open(args.load_history) as f:
                data = json.load(f)
                history = data.get("history", [])
                memory = data.get("memory", memory)
            print(f"History loaded ({len(history)} messages)\n")
        except Exception as e:
            print(f"Failed to load history: {e}\n")

    print("Chat mode (type 'quit' to exit, 'clear' to reset, 'mem' to show memory)\n")

    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            break

        if user_input.lower() == "quit":
            break
        elif user_input.lower() == "clear":
            history = []
            memory = {"topics": [], "entities": []}
            token_count = 0
            print("History and memory cleared.\n")
            continue
        elif user_input.lower() == "mem":
            print(f"\nMemory: Topics={memory['topics'][-3:]}\n")
            continue
        elif not user_input:
            continue

        context_msgs = " ".join([msg for pair in history[-2:] for msg in pair])
        system = build_system_prompt(args.system, context_msgs[:200] if context_msgs else "")
        prompt = f"{system}\n\nConversation:\n{context_msgs}\nYou: {user_input}\nAssistant:"

        result, elapsed = generate_text(generator, prompt, args)

        if result:
            response = result.split("Assistant:")[-1].strip() if "Assistant:" in result else result
            response = response[:200]
            
            print(f"Assistant: {response}\n")
            history.append((user_input, response))
            
            if args.enable_memory:
                keywords = extract_keywords(user_input) + extract_keywords(response)
                memory["topics"].extend(keywords[-3:])
                memory["topics"] = list(set(memory["topics"]))[-10:]
            
            token_count += args.max_tokens
        else:
            print("Error generating response.\n")

    if args.save_history:
        try:
            with open(args.save_history, "w") as f:
                json.dump({"history": history, "memory": memory}, f, indent=2, ensure_ascii=False)
            print(f"\nHistory saved to {args.save_history}")
        except Exception as e:
            print(f"\nFailed to save history: {e}")

    total_time = time.time() - start_time
    print(f"\nStats: {len(history)} exchanges, ~{token_count} tokens, {total_time:.1f}s total")
    print(f"Memory: {len(memory['topics'])} topics retained")


def main():
    args = build_parser().parse_args()

    if args.mode == "chat":
        chat_mode(args)
    else:
        single_mode(args)


if __name__ == "__main__":
    main()
